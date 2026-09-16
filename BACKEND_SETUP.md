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
- **Branch isolation**: two layers. `authorization.ts` rejects a request whose
  *arguments* name a branch outside `RPC_STAFF_BRANCHES`; handlers then check
  the branch *stored on each record*, so a lookup by id cannot cross branches.
  Client-supplied branch/entity values are never trusted, and staff branches
  fail closed when the env var is missing.

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
| `RPC_STAFF_BRANCHES` | **Required** staff branch allow-list (`GOREGAON,KANDIVALI`). Unset = staff see no branch data |
| `NEXT_PUBLIC_AUTH_ENABLED` | Web-app auth flag |
| `SESSION_SECRET` | Web-app session signing |
| `ADMIN_PASSWORD` / `STAFF_PASSWORD` | Legacy web logins, min 12 chars. There is no default: unset leaves the account unmanaged, and an account still on an old default password is locked on boot |

## Database (`DATABASE_URL`)

Schema lives in `db/schema.sql`; seed data in `db/seed.sql`; one-time real-data
import in `db/academyos_import.sql`. `db/apply.mjs` applies all three idempotently
on boot (`prestart`). The seed and the real-data import are themselves one-time migrations now — they used to re-run on every boot and resurrect deleted rows. apply.mjs then runs the one-time data migrations in its `MIGRATIONS`
list (recorded in `schema_migrations`, never re-run). Add cleanups there rather
than as boot-time deletes. Manual run against a fresh database:

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
node --experimental-strip-types --test backend-tests/*.test.ts
```

## Sync revisions

`api_syncChanges` reads the `entity_revisions` table. Every write handler bumps
the entities it touched (`bumpRevisions` in `src/lib/rpc/shared.ts`), so a
polling client reloads only what changed. An entity that has never been written
reads as 0. If you add a write handler, bump its entities there or the apps will
not refresh.

## Document numbering

Receipt numbers (`SMR-<fy>-NNN`) and school invoice numbers (`SMI-<fy>-NNN`)
come from the `doc_counters` table, incremented inside the same transaction
that writes the document, with a unique index on the number. The financial
year comes from the document date (April–March, IST), so the series rolls over
on its own. Numbers past 999 simply get a fourth digit.

## Security model

- Backend is authoritative for role, branches, permissions and identity.
- Stored device token is only a cached credential; validation happens server-side.
- Tokens are never logged, never included in exception messages, never persisted
  in shared preferences.