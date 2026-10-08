# StoreBuddy Real-Time Sync Reliability Plan

## Goal
Ensure every data change made on one device appears on all other devices in near real-time and that missed syncs are detectable.

## Current Event Flow (After Fix)
1. User action updates local state / database.
2. App queues operation in `sync_queue`.
3. App pushes queued operations to `POST /sync/push`.
4. Server writes:
   - latest entity snapshot in `SyncRecord`
   - ordered append-only event in `SyncEvent` (`seq`)
5. Server broadcasts websocket `sync_event` to tenant room.
6. Other devices apply event immediately.
7. Devices also run pull replay (`GET /sync/pull`) to recover any missed websocket event.

## New Debug/Audit Capabilities
- Client activity log stored per tenant key: `sync_activity_log_<tenantId>`
  - includes: queued operation, push acks, pull applied/noop, realtime event applied, sync start/success/failure.
- Server endpoint: `GET /api/v1/sync/audit?limit=200`
  - includes: seq, entity, entity_id, action, server_ts, source_device_id, source_user_id, payload.
- Device identity is propagated in header `x-device-id` and persisted on sync events.

## How To Map Device Actions vs Synced Events
1. On device A, perform a known action (example: create customer).
2. Check device A client activity log for:
   - `queue_operation`
   - `push_ack_accepted` with `seq`
3. Call server audit endpoint and verify same `seq/entity/entity_id` exists.
4. On device B, verify:
   - websocket: `realtime_event_applied` with same `seq`, or
   - pull recovery: `pull_applied` includes that `seq` range.
5. If an action exists in queue but not in server audit, push pipeline failed.
6. If in server audit but not applied on device B, realtime or pull application failed.

## Critical Reliability Rules
- Never skip pull ranges. Pull cursor must advance by last applied event seq, not server latest seq.
- Every delete payload must carry `id`/`_id` or derive it from `entity_id`.
- Every request should include `x-device-id` for source attribution.
- Do not call async queue operations inside `setState` without awaiting outside.

## Remaining Gaps To Address Next
1. Add a visible Sync Diagnostics page in the app to render `getRecentSyncActivity()`.
2. Persist local action IDs in UI actions (not only queue IDs) for easier cross-device tracing.
3. Add integration tests for:
   - websocket drop + pull recovery
   - pagination over >500 events
   - delete replay using `entity_id` fallback
4. Add stale queue alert when retry count exceeds threshold.
