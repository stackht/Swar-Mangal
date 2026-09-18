#!/usr/bin/env node
// Google Sheets mirror worker.
//
//   node sync/worker.mjs                     run forever (the service)
//   node sync/worker.mjs --once              drain one batch and exit
//   node sync/worker.mjs --status            what is waiting, and why
//   node sync/worker.mjs --backfill [table]  queue every existing row
//   node sync/worker.mjs --rebuild-index T   re-read tab T's ids into the index
//
// Env: DATABASE_URL, DATABASE_SSL=disable (same-host Postgres),
//      SHEETS_MIRROR_SPREADSHEET_ID, GOOGLE_SERVICE_ACCOUNT_JSON | GOOGLE_APPLICATION_CREDENTIALS,
//      SHEETS_SYNC_INTERVAL_MS (default 5000), SHEETS_SYNC_BATCH (default 200).
import pg from "pg";
import { createSheetsClient, credentialsFromEnv } from "./sheets-client.mjs";
import { enqueueBackfill, outboxStatus, rebuildIndex, syncOnce, MIRRORED_TABLES } from "./sheets-sync.mjs";

// Keep `date` columns as the string Postgres sends; parsing them to a JS Date
// at local midnight shifts them a day in IST.
pg.types.setTypeParser(1082, (v) => v);

const LOCK_KEY = 72_331_404; // pg advisory lock: only one mirror worker at a time
const args = process.argv.slice(2);
const has = (flag) => args.includes(flag);
const argAfter = (flag) => {
  const i = args.indexOf(flag);
  return i >= 0 ? args[i + 1] : undefined;
};

function log(message, extra) {
  const line = `[sheets-sync] ${new Date().toISOString()} ${message}`;
  console.log(extra ? `${line} ${JSON.stringify(extra)}` : line);
}

async function main() {
  if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL is not set");
  const db = new pg.Client({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_SSL === "disable" ? false : { rejectUnauthorized: false },
  });
  await db.connect();

  try {
    if (has("--status")) {
      const rows = await outboxStatus(db);
      if (!rows.length) console.log("Mirror is up to date: nothing waiting.");
      for (const r of rows) {
        console.log(
          `${r.table_name}: ${r.pending} waiting, oldest ${new Date(r.oldest).toISOString()}, attempts ${r.max_attempts}` +
            (r.last_error ? `\n  last error: ${r.last_error}` : ""),
        );
      }
      return;
    }

    if (has("--backfill")) {
      const one = argAfter("--backfill");
      const tables = one && !one.startsWith("--") ? [one] : MIRRORED_TABLES;
      log("backfill queued", await enqueueBackfill(db, tables));
      return;
    }

    const sheets = createSheetsClient({
      spreadsheetId: process.env.SHEETS_MIRROR_SPREADSHEET_ID,
      auth: credentialsFromEnv(),
    });

    if (has("--rebuild-index")) {
      const table = argAfter("--rebuild-index");
      if (!table) throw new Error("--rebuild-index needs a table name");
      log(`index rebuilt for ${table}`, await rebuildIndex({ db, sheets, table }));
      return;
    }

    const { rows } = await db.query(`select pg_try_advisory_lock($1) as ok`, [LOCK_KEY]);
    if (!rows[0].ok) throw new Error("Another sheets worker is already running (advisory lock held)");

    const batchSize = Number(process.env.SHEETS_SYNC_BATCH) || 200;
    const intervalMs = Number(process.env.SHEETS_SYNC_INTERVAL_MS) || 5000;

    if (has("--once")) {
      log("once", await syncOnce({ db, sheets, batchSize }));
      return;
    }

    let stopping = false;
    for (const signal of ["SIGTERM", "SIGINT"]) {
      process.on(signal, () => {
        log(`${signal} received, finishing the current batch`);
        stopping = true;
      });
    }

    log(`started: batch ${batchSize}, every ${intervalMs}ms, ${MIRRORED_TABLES.length} tables`);
    while (!stopping) {
      try {
        const stats = await syncOnce({ db, sheets, batchSize });
        if (stats.claimed) log("synced", stats);
        // A full batch means more is waiting: go again without sleeping.
        if (stats.claimed >= batchSize && !stats.failedTables.length) continue;
      } catch (err) {
        log(`batch failed: ${err.message}`);
      }
      await new Promise((r) => setTimeout(r, intervalMs));
    }
  } finally {
    await db.end().catch(() => {});
  }
}

main().catch((err) => {
  console.error(`[sheets-sync] FATAL ${err.message}`);
  process.exitCode = 1;
});
