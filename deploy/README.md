# Deploying Swar Mangal to the VPS

Postgres on the VPS is the **source of truth**. Every change is copied into a
separate Google Sheets **mirror workbook** by a background worker. A save never
waits on Google: if Sheets is slow or down, the change stays queued and retries.

```
Flutter app ──HTTPS──> proxy ──> app (Next.js /api/rpc) ──> Postgres
                                                              │ trigger, same transaction
                                                              v
                                   sheets-worker <── sheet_outbox ──> Google Sheets mirror
```

## 1. Google side (once)

1. In Google Cloud Console, create a project, enable the **Google Sheets API**.
2. Create a **service account**, then a **JSON key** for it. Download it.
3. Create a new, empty Google Sheet as the mirror (do not reuse the AcademyOS workbooks).
4. Share that sheet with the service account's email (`...@...iam.gserviceaccount.com`) as **Editor**.
5. Copy the sheet id from its URL: `docs.google.com/spreadsheets/d/<id>/edit`.

The key never goes in git, a chat, a screenshot or the APK. It lives only on the VPS.

## 2. First deploy

```bash
# on the VPS (Docker + Docker Compose plugin installed)
git clone <repo> /opt/swarmangal && cd /opt/swarmangal/deploy
cp .env.example .env            # fill in: passwords, tokens, RPC_STAFF_BRANCHES, APP_DOMAIN, SHEETS_MIRROR_SPREADSHEET_ID
mkdir -p secrets && chmod 700 secrets
# copy the JSON key to deploy/secrets/google-service-account.json, then:
chmod 600 secrets/google-service-account.json

docker compose up -d --build
```

Then HTTPS, one of:

- **Nothing else on ports 80/443:** `docker compose --profile proxy up -d` (Caddy gets a certificate for `APP_DOMAIN` automatically; point the domain's DNS A record at the VPS first).
- **nginx already running:** follow `nginx-swarmangal.conf`.

Check it:

```bash
curl -s -X POST https://$APP_DOMAIN/api/rpc -d 'function=api_dashboard&token=wrong'
# -> {"ok":false,"code":"AUTH_FAILED",...}
docker compose logs -f app sheets-worker
```

## 3. Moving the data from Railway (once)

```bash
RAILWAY_DATABASE_URL='<Railway DATABASE_PUBLIC_URL>' ./migrate-from-railway.sh
```

It reads Railway (never writes to it), restores into the VPS database, boots the
app so the schema and one-time migrations apply, and queues every row for the
mirror. Railway stays as it was, as a fallback, until the VPS is proven.

## 4. Pointing the phones at the VPS

- **Existing APKs:** login screen, gear icon, set the gateway to
  `https://<APP_DOMAIN>/api/rpc`, then log in with the tokens from `.env`.
- **New APKs:** change `founderApiUrl` / `staffApiUrl` in `lib/config.dart` and rebuild.

## 5. WhatsApp (once)

Messages go out from the academy's own WhatsApp number through the WA-AKG
gateway in this compose file. Staff tap **Send on WhatsApp** in the app; the
server looks up the student's registered number itself (the phone never
supplies a number), checks opt-outs, and records every message in
`wa_messages` (mirrored to Sheets).

1. Fill the `WA_*` values in `.env` (leave `WA_SEND_ENABLED=false`) and start:
   `docker compose up -d --build wa-db wa-akg`.
2. From your laptop open a tunnel, then browse to http://localhost:3080:
   `ssh -L 3080:127.0.0.1:3080 <user>@<vps>`
   Log in with `WA_AKG_ADMIN_EMAIL` / `WA_AKG_ADMIN_PASSWORD`.
3. **Sessions** → create a session (e.g. `swarmangal`) → scan the QR with the
   academy phone (WhatsApp → Linked devices). Put that id in `WA_AKG_SESSION_ID`.
4. **API Keys** → create a key → `WA_AKG_API_KEY`.
5. **Webhooks** → URL `http://app:3000/api/wa/webhook`, secret = `WA_WEBHOOK_SECRET`,
   event `message.status`. This is how "delivered"/"read" reaches the app.
6. Set `WA_ALLOWED_NUMBERS=<your own number>` and `WA_SEND_ENABLED=true`,
   `docker compose up -d app`, send a reminder to a test student that has your
   number, and confirm it arrives and turns DELIVERED.
7. Empty `WA_ALLOWED_NUMBERS` and `docker compose up -d app` to go live.

If the phone is logged out of linked devices, sends fail with
`WHATSAPP_SEND_FAILED`, the message is recorded as FAILED (never SENT), and
staff see the error: repeat step 3.
The pairing lives in the `wa_mysql` volume; losing it only means re-scanning.

## 6. Push notifications (once)

Founder and staff phones get a system notification — even fully closed —
when a draft needs approval, when the founder decides on one, and once a day
for fees due/overdue. This runs on Firebase Cloud Messaging (Google's push
service; free). Nothing changes on the phone until you finish this section —
until then the app just never asks for notification permission.

1. **Create the Firebase project** (console.firebase.google.com, no Google
   Cloud billing needed for this): "Add project" → name it (e.g.
   "Swar Mangal") → skip Google Analytics, it's not used.
2. **Register the Android app** inside that project: Project settings → your
   apps → Add app → Android. Package name **must** be exactly
   `in.swarmangal.academyos`. Download the `google-services.json` it offers.
3. **Put that file at** `android/app/google-services.json` in this repo,
   then rebuild the APK (`flutter build apk --release`) and reinstall it on
   every phone. This step alone turns on *receiving* push; the server also
   needs to be able to *send* it (next step).
4. **Create a service account key** for sending: in the Firebase console,
   Project settings → Service accounts → "Generate new private key" →
   downloads a JSON file. This is a secret — never in chat, git or a
   screenshot (same rule as the Sheets key).
5. On the VPS, base64-encode it and set it in `deploy/.env`:
   ```
   base64 -w0 /path/to/service-account.json
   ```
   Paste that single line as `FIREBASE_SERVICE_ACCOUNT_JSON` in `.env`, then
   `docker compose up -d app`.
6. Sign in on a phone (real login, not Demo — demo never registers a
   token) and allow the notification permission prompt. Submit a fee draft
   from a staff phone; the founder phone should get a notification within a
   few seconds, including with the app fully closed.
7. **Daily fees digest**: nothing in this app schedules anything itself
   (brief §2.4 — no triggers exist by rule), so an external cron calls the
   endpoint once a day:
   ```
   0 9 * * * curl -s -X POST https://<APP_DOMAIN>/api/rpc \
     -d function=api_founder_sendDailyDigest -d token=$RPC_FOUNDER_TOKEN >/dev/null
   ```
   Add that line with `crontab -e` on the VPS (or wherever has network
   access to the app). It is safe to call more than once a day — it just
   reports the same real counts each time, never a cached or guessed number.

If a phone never receives anything: check `api_pushStatus` returns
`enabled: true` (confirms the server's key is loaded), and that
`push_tokens` has a recent row for that phone (`push_log` shows every send
attempt and how many tokens it reached).

## 7. Self-service token registration/reset (once)

Instead of the founder running `db/mint_device_token.mjs` and sharing a
secret by hand, founder and staff can each register their own email in the
app (login screen → gear icon → "Set up my token"), verify a one-time code
sent to it, and the app logs in automatically. "Forgot / reset my token"
follows the same OTP flow. This needs a real mailbox to send from.

1. Use a Gmail account you control (a new one dedicated to this is fine —
   never the founder's or a student's personal address). Turn on
   2-Step Verification, then create an **App Password** at
   `myaccount.google.com/apppasswords` (not the normal Gmail password).
2. In `deploy/.env`, set `SMTP_USER` to that Gmail address and `SMTP_PASS`
   to the 16-character App Password. `SMTP_HOST`/`SMTP_PORT` already default
   to Gmail's; leave them unless using a different provider.
3. `docker compose up -d app`. Until `SMTP_USER`/`SMTP_PASS` are set, the
   feature refuses cleanly ("Email sending is not configured yet") instead
   of pretending to send.
4. **Staff must be added to the allow-list before they can register** — OTP
   only proves someone controls that inbox, not that they're staff. As
   founder: Home → About → "Manage staff access" → add their email (and
   branch, if different from the default). The founder's own email is fixed
   to `sharvil87@gmail.com` (override with `FOUNDER_EMAIL` in `.env` if
   needed) and needs no allow-list entry.
5. Test end to end on your own phone before telling staff: gear icon →
   "Set up my token" → your email → check for the code → enter it → the app
   should log you straight in.

Lost a phone? Founder → "Manage staff access" → find the device → Revoke.
That person can immediately self-register a new token with "Forgot / reset
my token" once you've re-confirmed they should still have access.

## Day to day

| Task | Command |
|---|---|
| Is the mirror up to date? | `docker compose exec sheets-worker node sync/worker.mjs --status` |
| Resend everything to Sheets | `docker compose exec sheets-worker node sync/worker.mjs --backfill` |
| Someone edited the mirror by hand | `docker compose exec sheets-worker node sync/worker.mjs --rebuild-index <table>` |
| Is WhatsApp connected? | `curl -s -H "X-API-Key: $WA_AKG_API_KEY" http://127.0.0.1:3080/api/sessions/$WA_AKG_SESSION_ID` |
| Stop all WhatsApp sending now | set `WA_SEND_ENABLED=false`, `docker compose up -d app` |
| Is push configured? | `curl -s -X POST https://<APP_DOMAIN>/api/rpc -d function=api_pushStatus -d token=$RPC_FOUNDER_TOKEN` |
| Send the fees digest right now | `curl -s -X POST https://<APP_DOMAIN>/api/rpc -d function=api_founder_sendDailyDigest -d token=$RPC_FOUNDER_TOKEN` |
| List issued device tokens | `curl -s -X POST https://<APP_DOMAIN>/api/rpc -d function=api_founder_listStaffTokens -d token=$RPC_FOUNDER_TOKEN` |
| Old way still works | `node db/mint_device_token.mjs "<label>" <FOUNDER_ADMIN\|OPS_USER>` — unaffected by the OTP flow |
| Update after a git pull | `git pull && docker compose up -d --build` |
| Nightly backup | cron: `15 2 * * * /opt/swarmangal/deploy/backup.sh >> /opt/swarmangal/deploy/backups/backup.log 2>&1` |
| Restore a backup | `docker compose exec -T db pg_restore -U $POSTGRES_USER -d $POSTGRES_DB --clean < backups/<file>.dump` |

## Rules the mirror keeps

- **One direction only.** Edits made in the mirror sheet are overwritten on the
  next change to that record. Correct data through the app.
- **Rows are never deleted** from the sheet (that would shift every row below).
  A deleted record shows `_deleted = TRUE`.
- **Columns are only ever added at the right.** Existing columns never move.
- **Not mirrored:** device tokens, user accounts, sessions, push tokens, the push send log.
- **The mirror is not a backup.** It can be rebuilt from Postgres; Postgres
  cannot be rebuilt from it. Keep the nightly dump.
- Only **one** worker runs at a time (a database lock enforces it).
