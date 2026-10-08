import { Router } from 'express';

import { requireAuth } from '../middleware/auth';
import { CounterModel } from '../models/Counter';
import { DeviceSessionModel } from '../models/DeviceSession';
import { SyncEventModel } from '../models/SyncEvent';
import { SyncRecordModel } from '../models/SyncRecord';

const syncRouter = Router();

const getNextSeq = async (): Promise<number> => {
  const counter = await CounterModel.findOneAndUpdate(
    { key: 'sync_event_seq' },
    { $inc: { value: 1 } },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
  return counter?.value ?? 1;
};

const touchDeviceSession = async (args: {
  tenantId: string;
  userId: string;
  deviceId?: string;
  deviceName?: string;
  recordPush?: boolean;
  recordPull?: boolean;
  lastAppliedSeq?: number;
  lastSyncStatus?: string;
  lastSyncError?: string;
}): Promise<void> => {
  if (!args.deviceId) {
    return;
  }

  const now = new Date();
  const setFields: Record<string, unknown> = {
    tenantId: args.tenantId,
    userId: args.userId,
    deviceId: args.deviceId,
    lastSeenAt: now,
  };

  if (args.deviceName) {
    setFields.deviceName = args.deviceName;
  }
  if (args.recordPush) {
    setFields.lastPushAt = now;
  }
  if (args.recordPull) {
    setFields.lastPullAt = now;
  }
  if (args.lastSyncStatus !== undefined) {
    setFields.lastSyncStatus = args.lastSyncStatus;
    setFields.lastSyncAt = now;
  }
  if (args.lastSyncError !== undefined) {
    setFields.lastSyncError = args.lastSyncError;
  }

  const update: Record<string, unknown> = { $set: setFields };
  if (typeof args.lastAppliedSeq === 'number') {
    update.$max = { lastAppliedSeq: args.lastAppliedSeq };
  }

  await DeviceSessionModel.findOneAndUpdate(
    {
      tenantId: args.tenantId,
      deviceId: args.deviceId,
    },
    update,
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
};

syncRouter.post('/push', requireAuth, async (req, res) => {
  const auth = req.auth;
  if (!auth) {
    res.status(401).json({ detail: 'Invalid token' });
    return;
  }

  const operationsRaw = (req.body?.operations ?? []) as Array<Record<string, unknown>>;
  const ack: Array<{
    client_op_id?: string;
    entity: string;
    entity_id: string;
    action: string;
    accepted: boolean;
    reason?: string;
    seq?: number;
  }> = [];

  let latestSeq = 0;

  // Wrap entire loop in try/catch so a mid-loop MongoDB error returns a proper
  // 500 instead of leaving the HTTP connection hanging (which the client would
  // see as a timeout and retry all ops, risking double-application).
  try {
    for (const op of operationsRaw) {
      const entity = String(op.entity ?? '').trim();
      const entityId = String(op.entity_id ?? '').trim();
      const action = String(op.action ?? 'UPSERT').trim().toUpperCase();
      const payload =
        op.payload && typeof op.payload === 'object'
          ? { ...(op.payload as Record<string, unknown>) }
          : ({} as Record<string, unknown>);
      const clientOpId = op.client_op_id ? String(op.client_op_id) : undefined;
      const updatedAtRaw = op.updated_at ? String(op.updated_at) : undefined;
      const eventTs = updatedAtRaw ? new Date(updatedAtRaw) : new Date();
      const eventTsIso = eventTs.toISOString();

      payload['id'] = entityId;
      payload['_id'] = entityId;
      if (auth.deviceId) {
        payload['deviceId'] = auth.deviceId;
      }
      payload['synced'] = true;
      payload['isSynced'] = true;

      const createdAt = String(payload['createdAt'] ?? '').trim();
      const updatedAt = String(payload['updatedAt'] ?? '').trim();
      if (!createdAt) {
        payload['createdAt'] = updatedAt || eventTsIso;
      }
      if (!updatedAt) {
        payload['updatedAt'] = createdAt || eventTsIso;
      }

      let normAction = String(action ?? '').trim().toUpperCase();
      if (normAction === 'INSERT' || normAction === 'UPDATE') {
        normAction = 'UPSERT';
      }

      if (!entity || !entityId || (normAction !== 'UPSERT' && normAction !== 'DELETE')) {
        ack.push({
          client_op_id: clientOpId,
          entity,
          entity_id: entityId,
          action,
          accepted: false,
          reason: 'invalid',
        });
        continue;
      }

      const existing = await SyncRecordModel.findOne({
        tenantId: auth.tenantId,
        entity,
        entityId,
      });

      // Reject if server already has the same or newer version (Last-Write-Wins).
      // Using <= (not <) also handles the rare equal-timestamp edge case: two
      // devices editing the same record at the same millisecond. In that case we
      // keep the server copy (first writer wins) rather than creating a duplicate
      // event.
      if (existing && existing.updatedAt && eventTs <= existing.updatedAt) {
        ack.push({
          client_op_id: clientOpId,
          entity,
          entity_id: entityId,
          action: normAction,
          accepted: false,
          reason: 'conflict',
        });
        continue;
      }

      await SyncRecordModel.findOneAndUpdate(
        {
          tenantId: auth.tenantId,
          entity,
          entityId,
        },
        {
          tenantId: auth.tenantId,
          entity,
          entityId,
          payload,
          deleted: normAction === 'DELETE',
          updatedAt: eventTs,
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );

      // Deduplicate: if a SyncEvent with this clientOpId already exists for this
      // tenant (e.g. the client retried after a partial server error), skip
      // creating a duplicate event and return the existing seq to the client.
      let isDuplicate = false;
      let eventSeq = 0;
      if (clientOpId) {
        const existingEvent = await SyncEventModel.findOne({
          tenantId: auth.tenantId,
          clientOpId,
        })
          .select('seq')
          .lean();
        if (existingEvent) {
          eventSeq = existingEvent.seq;
          isDuplicate = true;
        }
      }

      if (!isDuplicate) {
        // Only consume a sequence number when we are going to actually create
        // a new event. This prevents the Mongo counter from advancing on
        // every retried operation, leaving gaps in the sequential event log.
        const seq = await getNextSeq();
        latestSeq = Math.max(latestSeq, seq);
        eventSeq = seq;

        await SyncEventModel.create({
          seq,
          tenantId: auth.tenantId,
          entity,
          entityId,
          action: normAction,
          payload,
          serverTs: new Date(),
          sourceDeviceId: auth.deviceId,
          sourceUserId: auth.userId,
          clientOpId,
        });

        console.log(`Synced ${normAction} ${entity} ${entityId} for tenant ${auth.tenantId} seq ${seq}`);
      } else {
        console.log(`Duplicate op skipped: clientOpId=${clientOpId} tenant=${auth.tenantId} existing_seq=${eventSeq!}`);
      }

      ack.push({
        client_op_id: clientOpId,
        entity,
        entity_id: entityId,
        action: normAction,
        accepted: true,
        seq: eventSeq,
      });
    }

    await touchDeviceSession({
      tenantId: auth.tenantId,
      userId: auth.userId,
      deviceId: auth.deviceId,
      recordPush: operationsRaw.length > 0,
    });
  } catch (err) {
    console.error('Push handler error:', err);
    // Return a 500 with partial ack so the client knows which ops were
    // accepted before the error occurred and can avoid re-sending them.
    res.status(500).json({
      detail: 'Internal server error during push',
      latest_seq: latestSeq,
      accepted: ack,
    });
    return;
  }

  res.json({ latest_seq: latestSeq, accepted: ack });
});

syncRouter.get('/pull', requireAuth, async (req, res) => {
  const auth = req.auth;
  if (!auth) {
    res.status(401).json({ detail: 'Invalid token' });
    return;
  }

  const sinceSeq = Math.max(0, Number(req.query.since_seq ?? 0));
  const limit = Math.min(5000, Math.max(1, Number(req.query.limit ?? 500)));

  const rows = await SyncEventModel.find({
    tenantId: auth.tenantId,
    seq: { $gt: sinceSeq },
  })
    .sort({ seq: 1 })
    .limit(limit)
    .lean();

  const latestRow = await SyncEventModel.findOne({ tenantId: auth.tenantId })
    .sort({ seq: -1 })
    .lean();

  await touchDeviceSession({
    tenantId: auth.tenantId,
    userId: auth.userId,
    deviceId: auth.deviceId,
    recordPull: true,
  });

  res.json({
    from_seq: sinceSeq,
    latest_seq: latestRow?.seq ?? 0,
    events: rows.map((row) => ({
      seq: row.seq,
      entity: row.entity,
      entity_id: row.entityId,
      action: row.action,
      payload: row.payload,
      server_ts: row.serverTs,
      source_device_id: row.sourceDeviceId ?? null,
      source_user_id: row.sourceUserId ?? null,
      client_op_id: row.clientOpId ?? null,
    })),
  });

  console.log(`Pulled ${rows.length} events for tenant ${auth.tenantId} since ${sinceSeq}`);
});

syncRouter.get('/audit', requireAuth, async (req, res) => {
  const auth = req.auth;
  if (!auth) {
    res.status(401).json({ detail: 'Invalid token' });
    return;
  }

  const limit = Math.min(1000, Math.max(1, Number(req.query.limit ?? 200)));
  const rows = await SyncEventModel.find({ tenantId: auth.tenantId })
    .sort({ seq: -1 })
    .limit(limit)
    .lean();

  const latestSeq = rows.length > 0 ? rows[0].seq : 0;

  res.json({
    tenant_id: auth.tenantId,
    latest_seq: latestSeq,
    count: rows.length,
    events: rows.map((row) => ({
      seq: row.seq,
      entity: row.entity,
      entity_id: row.entityId,
      action: row.action,
      server_ts: row.serverTs,
      source_device_id: row.sourceDeviceId ?? null,
      source_user_id: row.sourceUserId ?? null,
      client_op_id: row.clientOpId ?? null,
      payload: row.payload,
    })),
  });
});

syncRouter.get('/journal', requireAuth, async (req, res) => {
  const auth = req.auth;
  if (!auth) {
    res.status(401).json({ detail: 'Invalid token' });
    return;
  }

  const limit = Math.min(1000, Math.max(1, Number(req.query.limit ?? 200)));
  const sinceSeq = Math.max(0, Number(req.query.since_seq ?? 0));
  const unseenOnly = String(req.query.unseen_only ?? 'false').toLowerCase() === 'true';
  const requestDeviceId = String(req.query.device_id ?? auth.deviceId ?? '').trim();
  const excludeOwnEvents =
    unseenOnly || String(req.query.exclude_own ?? 'false').toLowerCase() === 'true';

  const requestDevice = requestDeviceId
    ? await DeviceSessionModel.findOne({
        tenantId: auth.tenantId,
        deviceId: requestDeviceId,
      })
        .select('lastAppliedSeq')
        .lean()
    : null;
  const requestDeviceLastAppliedSeq = requestDevice?.lastAppliedSeq ?? 0;
  const effectiveSinceSeq = unseenOnly
    ? Math.max(sinceSeq, requestDeviceLastAppliedSeq)
    : sinceSeq;

  const eventQuery: Record<string, unknown> = {
    tenantId: auth.tenantId,
  };
  if (effectiveSinceSeq > 0) {
    eventQuery.seq = { $gt: effectiveSinceSeq };
  }
  if (excludeOwnEvents && requestDeviceId.length > 0) {
    eventQuery.sourceDeviceId = { $ne: requestDeviceId };
  }

  const [events, latestEvent, deviceSessions] = await Promise.all([
    SyncEventModel.find(eventQuery)
      .sort(effectiveSinceSeq > 0 || unseenOnly ? { seq: 1 } : { seq: -1 })
      .limit(limit)
      .lean(),
    SyncEventModel.findOne({ tenantId: auth.tenantId })
      .sort({ seq: -1 })
      .select('seq')
      .lean(),
    DeviceSessionModel.find({ tenantId: auth.tenantId })
      .sort({ lastSeenAt: -1 })
      .lean(),
  ]);

  const latestSeq = latestEvent?.seq ?? 0;
  const deviceProgress = deviceSessions.map((device) => ({
    deviceId: device.deviceId,
    lastAppliedSeq: device.lastAppliedSeq ?? 0,
  }));

  res.json({
    tenant_id: auth.tenantId,
    request_device_id: requestDeviceId.length > 0 ? requestDeviceId : null,
    request_device_last_applied_seq: requestDeviceLastAppliedSeq,
    effective_since_seq: effectiveSinceSeq,
    unseen_only: unseenOnly,
    latest_seq: latestSeq,
    events: events.map((row) => ({
      seen_by_device_ids: deviceProgress
        .filter((device) => device.lastAppliedSeq >= row.seq)
        .map((device) => device.deviceId),
      pending_device_ids: deviceProgress
        .filter((device) => device.lastAppliedSeq < row.seq)
        .map((device) => device.deviceId),
      seen_by_request_device:
        requestDeviceId.length > 0
          ? requestDeviceLastAppliedSeq >= row.seq
          : null,
      seq: row.seq,
      entity: row.entity,
      entity_id: row.entityId,
      action: row.action,
      payload: row.payload,
      server_ts: row.serverTs,
      source_device_id: row.sourceDeviceId ?? null,
      source_user_id: row.sourceUserId ?? null,
      client_op_id: row.clientOpId ?? null,
    })),
    devices: deviceSessions.map((device) => ({
      tenant_id: device.tenantId,
      user_id: device.userId,
      device_id: device.deviceId,
      device_name: device.deviceName,
      last_seen_at: device.lastSeenAt,
      last_push_at: device.lastPushAt ?? null,
      last_pull_at: device.lastPullAt ?? null,
      last_sync_at: device.lastSyncAt ?? null,
      last_applied_seq: device.lastAppliedSeq ?? 0,
      last_sync_status: device.lastSyncStatus ?? 'unknown',
      last_sync_error: device.lastSyncError ?? '',
      lag: Math.max(0, latestSeq - (device.lastAppliedSeq ?? 0)),
    })),
  });
});

syncRouter.get('/snapshot/:entity', requireAuth, async (req, res) => {
  const auth = req.auth;
  if (!auth) {
    res.status(401).json({ detail: 'Invalid token' });
    return;
  }

  const entity = String(req.params.entity ?? '').trim();
  const includeDeleted = String(req.query.include_deleted ?? 'false').toLowerCase() === 'true';

  const query: Record<string, unknown> = {
    tenantId: auth.tenantId,
    entity,
  };

  if (!includeDeleted) {
    query.deleted = false;
  }

  const rows = await SyncRecordModel.find(query).lean();

  res.json({
    entity,
    items: rows.map((row) => ({
      entity_id: row.entityId,
      payload: row.payload,
      deleted: row.deleted,
      updated_at: row.updatedAt,
    })),
  });
});

/**
 * GET /sync/status
 * Lightweight heartbeat that returns the tenant's current latest_seq and
 * the number of pending items in the queue without transferring any payloads.
 * Clients use this to decide whether a pull is needed before doing a full
 * /sync/pull, avoiding unnecessary network traffic on the 15 s poll cycle.
 */
syncRouter.get('/status', requireAuth, async (req, res) => {
  const auth = req.auth;
  if (!auth) {
    res.status(401).json({ detail: 'Invalid token' });
    return;
  }

  try {
    // Find the highest seq for this tenant in a single indexed query.
    const latestRow = await SyncEventModel.findOne({ tenantId: auth.tenantId })
      .sort({ seq: -1 })
      .select('seq')
      .lean();

    res.json({
      tenant_id: auth.tenantId,
      latest_seq: latestRow?.seq ?? 0,
    });
  } catch (err) {
    console.error('Status endpoint error:', err);
    res.status(500).json({ detail: 'Failed to fetch sync status' });
  }
});

/**
 * GET /sync/full-snapshot
 * Returns the complete current state of ALL entities for a tenant by reading
 * the SyncRecord master table (one record per entity instance, no event log).
 * Used by a fresh device on first login (local_seq = 0) so it can bootstrap
 * directly from server state instead of replaying every historical SyncEvent.
 *
 * Response shape:
 *   { latest_seq, records: [{ entity, entity_id, payload, updated_at }] }
 */
syncRouter.get('/full-snapshot', requireAuth, async (req, res) => {
  const auth = req.auth;
  if (!auth) {
    res.status(401).json({ detail: 'Invalid token' });
    return;
  }

  try {
    // Fetch the current latest_seq so the client knows where to resume
    // incremental pulls from after applying this snapshot.
    const latestSeqRow = await SyncEventModel.findOne({ tenantId: auth.tenantId })
      .sort({ seq: -1 })
      .select('seq')
      .lean();

    const latestSeq = latestSeqRow?.seq ?? 0;

    // Fetch all non-deleted records for this tenant.
    const records = await SyncRecordModel.find({
      tenantId: auth.tenantId,
      deleted: false,
    }).lean();

    await touchDeviceSession({
      tenantId: auth.tenantId,
      userId: auth.userId,
      deviceId: auth.deviceId,
      recordPull: true,
    });

    res.json({
      latest_seq: latestSeq,
      records: records.map((r) => ({
        entity: r.entity,
        entity_id: r.entityId,
        payload: r.payload,
        updated_at: r.updatedAt,
      })),
    });

    console.log(
      `Full snapshot for tenant ${auth.tenantId}: ${records.length} records at seq=${latestSeq}`
    );
  } catch (err) {
    console.error('Full snapshot error:', err);
    res.status(500).json({ detail: 'Failed to generate full snapshot' });
  }
});

syncRouter.post('/device-state', requireAuth, async (req, res) => {
  const auth = req.auth;
  if (!auth) {
    res.status(401).json({ detail: 'Invalid token' });
    return;
  }

  if (!auth.deviceId) {
    res.status(422).json({ detail: 'Device id is required' });
    return;
  }

  const body = (req.body ?? {}) as Record<string, unknown>;
  const lastAppliedSeq = Number(body.last_applied_seq ?? body.lastAppliedSeq ?? 0);
  const lastSyncStatus = String(
    body.last_sync_status ?? body.lastSyncStatus ?? 'healthy'
  )
    .trim()
    .toLowerCase();
  const lastSyncError = String(
    body.last_sync_error ?? body.lastSyncError ?? ''
  ).trim();
  const deviceName = String(body.device_name ?? body.deviceName ?? '').trim();

  await touchDeviceSession({
    tenantId: auth.tenantId,
    userId: auth.userId,
    deviceId: auth.deviceId,
    deviceName: deviceName.length === 0 ? undefined : deviceName,
    lastAppliedSeq: Number.isFinite(lastAppliedSeq) ? lastAppliedSeq : 0,
    lastSyncStatus:
        lastSyncStatus.length === 0 ? 'healthy' : lastSyncStatus,
    lastSyncError,
  });

  res.json({
    tenant_id: auth.tenantId,
    device_id: auth.deviceId,
    last_applied_seq: Number.isFinite(lastAppliedSeq) ? lastAppliedSeq : 0,
    last_sync_status:
        lastSyncStatus.length === 0 ? 'healthy' : lastSyncStatus,
    last_sync_error: lastSyncError,
  });
});

export { syncRouter };
