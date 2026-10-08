import fs from 'fs';
import path from 'path';

import Database from 'better-sqlite3';

import { connectDb } from '../db';
import { CounterModel } from '../models/Counter';
import { DeviceSessionModel } from '../models/DeviceSession';
import { SyncEventModel } from '../models/SyncEvent';
import { SyncRecordModel } from '../models/SyncRecord';
import { TenantModel } from '../models/Tenant';
import { UserModel } from '../models/User';
import { hashPassword } from '../utils/password';

type SQLiteRow = Record<string, unknown>;

const getArgValue = (name: string): string | null => {
  const prefix = `${name}=`;
  const direct = process.argv.find((arg) => arg.startsWith(prefix));
  if (direct) return direct.slice(prefix.length);

  const index = process.argv.findIndex((arg) => arg === name);
  if (index >= 0 && process.argv[index + 1]) {
    return process.argv[index + 1];
  }
  return null;
};

const getExistingTable = (db: Database.Database, options: string[]): string | null => {
  for (const tableName of options) {
    const row = db
      .prepare("SELECT name FROM sqlite_master WHERE type='table' AND name = ?")
      .get(tableName) as SQLiteRow | undefined;
    if (row?.name) {
      return String(row.name);
    }
  }
  return null;
};

const getRows = (db: Database.Database, tableOptions: string[]): SQLiteRow[] => {
  const tableName = getExistingTable(db, tableOptions);
  if (!tableName) return [];
  return db.prepare(`SELECT * FROM ${tableName}`).all() as SQLiteRow[];
};

const asString = (value: unknown): string => {
  if (value === null || value === undefined) return '';
  return String(value);
};

const asBool = (value: unknown, defaultValue = false): boolean => {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true' || normalized === '1') return true;
    if (normalized === 'false' || normalized === '0') return false;
  }
  return defaultValue;
};

const asDate = (value: unknown, fallback = new Date()): Date => {
  if (!value) return fallback;
  const parsed = new Date(String(value));
  return Number.isNaN(parsed.getTime()) ? fallback : parsed;
};

const migrate = async (): Promise<void> => {
  const argPath = getArgValue('--sqlite');
  const defaultPath = path.resolve(process.cwd(), 'legacy', 'storebuddy_sync.db');
  const sqlitePath = argPath ? path.resolve(process.cwd(), argPath) : defaultPath;

  // eslint-disable-next-line no-console
  console.log(`Using SQLite file: ${sqlitePath}`);

  if (!fs.existsSync(sqlitePath)) {
    const expectedDefault = path.resolve(process.cwd(), 'legacy', 'storebuddy_sync.db');
    const guidance = [
      `SQLite source file was not found: ${sqlitePath}`,
      `Default expected path: ${expectedDefault}`,
      'How to fix:',
      `1) Place your backup file at: ${expectedDefault}`,
      '2) Or run with a direct path:',
      '   npm run migrate:sqlite -- --sqlite "D:/full/path/to/storebuddy_sync.db"',
    ].join('\n');

    throw new Error(guidance);
  }

  const sqlite = new Database(sqlitePath, { readonly: true, fileMustExist: true });

  await connectDb();

  const tenants = getRows(sqlite, ['tenant', 'tenants']);
  const users = getRows(sqlite, ['user', 'users']);
  const deviceSessions = getRows(sqlite, ['devicesession', 'device_session', 'device_sessions']);
  const syncRecords = getRows(sqlite, ['syncrecord', 'sync_record', 'sync_records']);
  const syncEvents = getRows(sqlite, ['syncevent', 'sync_event', 'sync_events']);

  let tenantCount = 0;
  let userCount = 0;
  let deviceCount = 0;
  let recordCount = 0;
  let eventCount = 0;

  const userIdMap = new Map<string, string>();

  for (const row of tenants) {
    const tenantId = asString(row.tenant_id || row.tenantId).trim().toLowerCase();
    if (!tenantId) continue;

    await TenantModel.findOneAndUpdate(
      { tenantId },
      {
        tenantId,
        storeName: asString(row.store_name || row.storeName || tenantId),
        ownerEmail: asString(row.owner_email || row.ownerEmail).trim().toLowerCase(),
        trialStartsAt: asDate(row.trial_starts_at || row.trialStartsAt),
        trialEndsAt: asDate(row.trial_ends_at || row.trialEndsAt),
        trialActive: asBool(row.trial_active || row.trialActive, true),
        createdAt: asDate(row.created_at || row.createdAt),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    tenantCount += 1;
  }

  for (const row of users) {
    const email = asString(row.email).trim().toLowerCase();
    if (!email) continue;

    const oldUserId = asString(row.id);
    const rawPasswordHash = asString(row.password_hash || row.passwordHash);
    const passwordHash = rawPasswordHash || (await hashPassword('ChangeMe123!'));

    const updated = await UserModel.findOneAndUpdate(
      { email },
      {
        tenantId: asString(row.tenant_id || row.tenantId).trim().toLowerCase(),
        name: asString(row.name || email),
        email,
        role: asString(row.role || 'manager'),
        passwordHash,
        active: asBool(row.active, true),
        createdAt: asDate(row.created_at || row.createdAt),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    if (updated && oldUserId) {
      userIdMap.set(oldUserId, String(updated._id));
    }

    userCount += 1;
  }

  for (const row of deviceSessions) {
    const tenantId = asString(row.tenant_id || row.tenantId).trim().toLowerCase();
    const deviceId = asString(row.device_id || row.deviceId);
    if (!tenantId || !deviceId) continue;

    const oldUserId = asString(row.user_id || row.userId);
    const mappedUserId = userIdMap.get(oldUserId) ?? oldUserId;

    await DeviceSessionModel.findOneAndUpdate(
      { tenantId, deviceId },
      {
        tenantId,
        userId: mappedUserId,
        deviceId,
        deviceName: asString(row.device_name || row.deviceName || 'Unknown Device'),
        lastSeenAt: asDate(row.last_seen_at || row.lastSeenAt),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    deviceCount += 1;
  }

  for (const row of syncRecords) {
    const tenantId = asString(row.tenant_id || row.tenantId).trim().toLowerCase();
    const entity = asString(row.entity);
    const entityId = asString(row.entity_id || row.entityId);
    if (!tenantId || !entity || !entityId) continue;

    let payload: Record<string, unknown> = {};
    const rawPayload = row.payload;
    if (typeof rawPayload === 'string') {
      try {
        payload = JSON.parse(rawPayload) as Record<string, unknown>;
      } catch {
        payload = {};
      }
    } else if (rawPayload && typeof rawPayload === 'object') {
      payload = rawPayload as Record<string, unknown>;
    }

    await SyncRecordModel.findOneAndUpdate(
      { tenantId, entity, entityId },
      {
        tenantId,
        entity,
        entityId,
        payload,
        deleted: asBool(row.deleted, false),
        updatedAt: asDate(row.updated_at || row.updatedAt),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    recordCount += 1;
  }

  let maxSeq = 0;
  for (const row of syncEvents) {
    const seq = Number(row.seq || 0);
    const tenantId = asString(row.tenant_id || row.tenantId).trim().toLowerCase();
    const entity = asString(row.entity);
    const entityId = asString(row.entity_id || row.entityId);
    if (!seq || !tenantId || !entity || !entityId) continue;

    let payload: Record<string, unknown> = {};
    const rawPayload = row.payload;
    if (typeof rawPayload === 'string') {
      try {
        payload = JSON.parse(rawPayload) as Record<string, unknown>;
      } catch {
        payload = {};
      }
    } else if (rawPayload && typeof rawPayload === 'object') {
      payload = rawPayload as Record<string, unknown>;
    }

    await SyncEventModel.findOneAndUpdate(
      { seq },
      {
        seq,
        tenantId,
        entity,
        entityId,
        action: asString(row.action || 'UPSERT').toUpperCase(),
        payload,
        serverTs: asDate(row.server_ts || row.serverTs),
        sourceDeviceId: asString(row.source_device_id || row.sourceDeviceId || '') || undefined,
        sourceUserId: asString(row.source_user_id || row.sourceUserId || '') || undefined,
        clientOpId: asString(row.client_op_id || row.clientOpId || '') || undefined,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    maxSeq = Math.max(maxSeq, seq);
    eventCount += 1;
  }

  if (maxSeq > 0) {
    await CounterModel.findOneAndUpdate(
      { key: 'sync_event_seq' },
      { key: 'sync_event_seq', value: maxSeq },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }

  sqlite.close();

  // eslint-disable-next-line no-console
  console.log(
    `Migration complete. Tenants: ${tenantCount}, Users: ${userCount}, Devices: ${deviceCount}, SyncRecords: ${recordCount}, SyncEvents: ${eventCount}`
  );

  process.exit(0);
};

migrate().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Migration failed:', error);
  process.exit(1);
});
