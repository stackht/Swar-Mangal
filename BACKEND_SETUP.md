# Swar Mangal — Backend Setup

Swar Mangal is a **zero-Google-Script** stack:

```
[ Flutter Android APK ]  --HTTPS POST function=<api>&token=<deviceToken>&arg=<json>-->  [ Railway /api/rpc ]
                                                                                              |  Next.js / Node.js
                                                                                              |  token auth -> RPC authz -> handler
                                                                                              v
                                                                                    [ PostgreSQL ]
```

No Google Apps Script. No Google Sheets. No `clasp`. No `/exec`. No `MobileApiGateway`.

## Architecture

- **Client**: Flutter Android APK. Talks RPC to `https://swarmangal-app-production.up.railway.app/api/rpc`.
- **Backend**: Next.js / Node.js deployed on Railway. Exposes a single RPC entry point (`POST /api/rpc`).
- **Database**: PostgreSQL (Railway-managed). Connected via `DATABASE_URL`.
- **Authentication**: Founder/Staff device tokens (`RPC_FOUNDER_TOKEN`, `RPC_STAFF_TOKEN`).
- **Authorization**: Centralized fail-closed policy — every RPC function lists its
  minimum role (`FOUNDER` / `STAFF`); unknown functions and wrong-role calls are
  rejected before the handler runs (see `src/lib/rpc/authorization.ts`).
- **Branch isolation**: staff sessions are scoped to allowed branches; founder
  sees all. Client-supplied branch/entity values are never trusted.

## RPC contract

```
POST /api/rpc
Content-Type: application/x-www-form-urlencoded

function=<api_name>
token=<device_token>
arg=<json>
```

Response is always JSON:

```json
{ "ok": true, ... }
```

Errors use machine-readable codes:
- `AUTH_FAILED` — missing/invalid token
- `ROLE_FORBIDDEN` — authenticated but wrong role for this function
- `BRANCH_FORBIDDEN` — staff requesting an unauthorized branch
- `UNKNOWN_API` — function not in the authorization policy (fail closed)
- `SERVER_ERROR` — backend exception (never leaks stack traces/secrets)

## Environment variables (Railway)

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `RPC_FOUNDER_TOKEN` | Founder device token (`FOUNDER_ADMIN` role) |
| `RPC_STAFF_TOKEN` | Staff device token (`OPS_USER` role) |
| `RPC_STAFF_BRANCHES` | Optional staff branch allow-list (`GOREGAON,KANDIVALI`) |
| `NEXT_PUBLIC_AUTH_ENABLED` | Web-app auth flag |
| `SESSION_SECRET` | Web-app session signing |

## Database (`DATABASE_URL`)

Schema lives in `db/schema.sql`; seed data in `db/seed.sql`; one-time real-data
import in `db/academyos_import.sql`. `db/apply.mjs` applies all three idempotently
on boot (`prestart`). Manual run against a fresh database:

```
psql "$DATABASE_URL" -f db/schema.sql
psql "$DATABASE_URL" -f db/seed.sql
```

## API key surfaces (Flutter side)

- Production RPC URL is set in `lib/config.dart` (`founderExecUrl` / `staffExecUrl`).
- Login screen accepts a custom gateway URL (validated: https + `/api/rpc`, rejects
  placeholders and legacy Google URLs).
- The device token is stored in **secure storage** (`lib/core/session_storage.dart`),
  never SharedPreferences, never logged.

## Build commands

```
# Flutter app
flutter pub get
flutter analyze
flutter test
flutter build apk --release

# Backend
npm install
npm run typecheck
npm run build
node --experimental-strip-types --test test/rpc_authorization.test.ts
```

## Security model

- Backend is authoritative for role, branches, permissions and identity.
- Stored device token is only a cached credential; validation happens server-side.
- Tokens are never logged, never included in exception messages, never persisted
  in shared preferences.