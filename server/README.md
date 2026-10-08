# StoreBuddy Sync Server (TypeScript + MongoDB)

This is the TypeScript replacement for the previous Python backend.

## Stack

- Node.js + Express
- TypeScript
- MongoDB + Mongoose
- JWT auth
- HTTP polling for sync updates (`/sync/status` + `/sync/pull`)

## Setup

1. Install dependencies:

```bash
npm install
```

2. Optional: create `.env` from example (defaults are built in, so `.env` is not required for local run):

```bash
copy .env.example .env
```

3. If you create `.env`, update values, especially:

- `JWT_SECRET`
- `MONGODB_URI`
- `PLATFORM_ADMIN_EMAIL`
- `PLATFORM_ADMIN_PASSWORD`

4. Run in development:

```bash
npm run dev
```

5. Production build:

```bash
npm run build
npm start
```

Server default URL: `http://localhost:8080`
API prefix: `/api/v1`

## Migrate Existing SQLite Data

If you have old SQLite data, copy the database file to
`server/realtime_sync_backend_ts/legacy/storebuddy_sync.db` and run:

```bash
npm run migrate:sqlite
```

You can also pass a custom path:

```bash
npm run migrate:sqlite -- --sqlite ../path/to/storebuddy_sync.db
```

If you omit `--sqlite`, it defaults to `legacy/storebuddy_sync.db`.

The migration imports tenants, users, device sessions, sync records, and sync events,
and sets the sync sequence counter to the latest imported event sequence.

## Compatible API Endpoints

- `GET /health`
- `POST /api/v1/auth/register-store`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/platform/stores`
- `POST /api/v1/auth/platform/stores/:tenantId/trial/reactivate`
- `POST /api/v1/sync/push`
- `GET /api/v1/sync/status`
- `GET /api/v1/sync/pull`
- `GET /api/v1/sync/full-snapshot`
- `GET /api/v1/sync/snapshot/:entity`

## Notes

- Platform tenant/admin are auto-bootstrapped on startup.
- Trial lifecycle is strict: expired trials are blocked until platform admin reactivates.
- User email is globally unique across tenants.
- This backend is the primary server implementation for the project.
