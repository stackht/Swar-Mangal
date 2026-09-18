// ============================================================================
// Postgres -> Google Sheets mirror engine.
//
// Postgres is the source of truth. Triggers (db/schema.sql) enqueue the
// primary key of every changed row into sheet_outbox inside the writing
// transaction. This engine drains that queue into a mirror workbook: one tab
// per table, one row per record, header row = column names.
//
// Rules it keeps:
//  * A save never waits on Google. Failures stay queued and retry with backoff.
//  * ADD-RIGHT ONLY: new columns are appended at the far right; existing
//    columns are never reordered, renamed or removed.
//  * Rows are never deleted from the sheet (that would shift every row after
//    it). A deleted record is marked _deleted = TRUE.
//  * Values are written RAW, so text beginning with "=" is never a formula.
//  * One worker at a time (the worker holds an advisory lock).
//
// Dependencies are injected (db, sheets) so the engine is testable against a
// real Postgres engine with an in-memory sheet.
// ============================================================================

/** Tables copied to the mirror. Secrets (device_tokens, users, sessions) never are. */
export const MIRRORED_TABLES = [
  "students_acad", "teachers_acad", "receipts", "money_ledger", "expenses", "expense_drafts",
  "payment_drafts", "teacher_payouts", "payout_attributions", "payout_rules", "timetable",
  "attendance_acad", "scheduled_sessions", "inquiries", "school_invoices_rpc", "audit_log",
  "entities", "schools", "wa_messages", "student_drafts",
  "period_locks", "receipt_corrections", "school_invoice_drafts",
  "package_extension_requests", "entity_payment_profiles", "payment_profile_change_requests",
  "closure_calendar", "class_outcome_corrections", "late_fee_waiver_requests",
  "instalment_plan_drafts", "instalment_plans", "instalment_plan_items",
  "terms_acceptance_tokens", "manual_terms_acceptance_requests", "inquiry_followups",
];

/** Bookkeeping columns the mirror adds to every tab. */
export const META_COLUMNS = ["_deleted", "_synced_at"];

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

/** 1 -> A, 26 -> Z, 27 -> AA. */
export function columnLetter(n) {
  let s = "";
  let x = n;
  while (x > 0) {
    const rem = (x - 1) % 26;
    s = String.fromCharCode(65 + rem) + s;
    x = Math.floor((x - 1) / 26);
  }
  return s;
}

/** Timestamp as the academy reads it: IST, "YYYY-MM-DD HH:mm:ss". */
export function istTimestamp(date) {
  return new Date(date.getTime() + IST_OFFSET_MS).toISOString().slice(0, 19).replace("T", " ");
}

const NUMERIC_TYPES = new Set(["numeric", "integer", "bigint", "smallint", "real", "double precision"]);

/**
 * One database value -> one RAW sheet cell.
 * `dataType` is information_schema.columns.data_type.
 *
 * DATE TRAP: node-postgres parses a `date` column into a JS Date at LOCAL
 * midnight, and toISOString() on that lands on the previous day in IST. The
 * worker therefore registers a string parser for `date`; a Date that still
 * reaches here for a `date` column is one parsed at UTC midnight (PGlite).
 */
export function toCell(value, dataType = "") {
  if (value === null || value === undefined) return "";
  if (value instanceof Date) {
    if (dataType === "date") return value.toISOString().slice(0, 10);
    return istTimestamp(value);
  }
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return Number.isFinite(value) ? value : "";
  if (typeof value === "bigint") return Number(value);
  if (typeof value === "object") return JSON.stringify(value);
  if (NUMERIC_TYPES.has(dataType)) {
    const n = Number(value);
    return Number.isFinite(n) ? n : String(value);
  }
  return String(value);
}

/**
 * Merge the sheet's existing header with the columns we need, ADD-RIGHT ONLY.
 * Existing columns keep their position; missing ones are appended in order.
 */
export function mergeHeader(existing, wanted) {
  const header = (existing ?? []).map((h) => String(h ?? ""));
  const have = new Set(header);
  let changed = header.length === 0;
  for (const col of wanted) {
    if (!have.has(col)) {
      header.push(col);
      have.add(col);
      changed = true;
    }
  }
  return { header, changed };
}

/** "'receipts'!A12:K14" -> { firstRow: 12, lastRow: 14 }. */
export function parseUpdatedRange(range) {
  const m = /!([A-Z]+)(\d+)(?::([A-Z]+)(\d+))?$/.exec(String(range ?? ""));
  if (!m) throw new Error(`Unexpected updatedRange: ${range}`);
  const firstRow = Number(m[2]);
  return { firstRow, lastRow: m[4] ? Number(m[4]) : firstRow };
}

/** Retry delay after N failed attempts: 10s, 20s, 40s ... capped at 15 minutes. */
export function retryDelaySeconds(attempts) {
  return Math.min(10 * 2 ** Math.max(0, attempts - 1), 900);
}

async function tableColumns(db, table) {
  const { rows } = await db.query(
    `select column_name, data_type from information_schema.columns
     where table_schema = 'public' and table_name = $1 order by ordinal_position`,
    [table],
  );
  return rows;
}

/**
 * Drain one batch of the outbox. Returns counts for logging.
 * Claiming pushes next_attempt_at forward first, so a crash mid-batch simply
 * lets those rows retry later instead of losing them.
 */
export async function syncOnce({ db, sheets, batchSize = 200, now = () => new Date() }) {
  const claimed = (
    await db.query(
      `update sheet_outbox
       set next_attempt_at = now() + interval '2 minutes', attempts = attempts + 1
       where id in (
         select id from sheet_outbox where next_attempt_at <= now()
         order by id limit $1 for update skip locked
       )
       returning id, table_name, row_pk, op, attempts`,
      [batchSize],
    )
  ).rows;

  const stats = { claimed: claimed.length, written: 0, appended: 0, markedDeleted: 0, failedTables: [] };
  if (!claimed.length) return stats;

  // Coalesce: many events for one record become one write of its latest state.
  const byTable = new Map();
  for (const ev of claimed) {
    if (!MIRRORED_TABLES.includes(ev.table_name)) {
      // Not (or no longer) mirrored: drop it rather than retry forever.
      await db.query(`delete from sheet_outbox where id = $1`, [ev.id]);
      continue;
    }
    if (!byTable.has(ev.table_name)) byTable.set(ev.table_name, { ids: [], pks: new Set(), attempts: 0 });
    const group = byTable.get(ev.table_name);
    group.ids.push(Number(ev.id));
    group.pks.add(String(ev.row_pk));
    group.attempts = Math.max(group.attempts, Number(ev.attempts));
  }

  const stamp = istTimestamp(now());

  for (const table of MIRRORED_TABLES) {
    const group = byTable.get(table);
    if (!group) continue;
    const pks = [...group.pks];
    try {
      const cols = await tableColumns(db, table);
      const typeOf = new Map(cols.map((c) => [c.column_name, c.data_type]));
      const wanted = ["id", ...cols.map((c) => c.column_name).filter((c) => c !== "id"), ...META_COLUMNS];

      await sheets.ensureTab(table);
      const { header, changed } = mergeHeader(await sheets.getHeader(table), wanted);
      if (changed) await sheets.setHeader(table, header);

      const rows = (await db.query(`select * from ${quoteIdent(table)} where id::text = any($1)`, [pks])).rows;
      const byPk = new Map(rows.map((r) => [String(r.id), r]));
      const index = new Map(
        (
          await db.query(
            `select row_pk, row_number from sheet_row_index where table_name = $1 and row_pk = any($2)`,
            [table, pks],
          )
        ).rows.map((r) => [String(r.row_pk), Number(r.row_number)]),
      );

      const updates = [];
      const appends = [];
      const deletedCol = header.indexOf("_deleted") + 1;
      const syncedCol = header.indexOf("_synced_at") + 1;

      for (const pk of pks) {
        const record = byPk.get(pk);
        const rowNumber = index.get(pk);
        if (record) {
          const values = header.map((h) => {
            if (h === "_deleted") return false;
            if (h === "_synced_at") return stamp;
            return h in record ? toCell(record[h], typeOf.get(h)) : "";
          });
          if (rowNumber) updates.push({ startCell: `A${rowNumber}`, values: [values] });
          else appends.push({ pk, values });
        } else if (rowNumber) {
          // Gone from the database: mark it, never delete the sheet row.
          updates.push({ startCell: `${columnLetter(deletedCol)}${rowNumber}`, values: [[true]] });
          updates.push({ startCell: `${columnLetter(syncedCol)}${rowNumber}`, values: [[stamp]] });
          stats.markedDeleted++;
        }
        // Deleted before it was ever mirrored: nothing to write.
      }

      if (updates.length) {
        await sheets.batchUpdate(table, updates);
        stats.written += updates.length;
      }
      if (appends.length) {
        const { firstRow } = await sheets.appendRows(table, appends.map((a) => a.values));
        for (let i = 0; i < appends.length; i++) {
          await db.query(
            `insert into sheet_row_index (table_name, row_pk, row_number) values ($1,$2,$3)
             on conflict (table_name, row_pk) do update set row_number = excluded.row_number`,
            [table, appends[i].pk, firstRow + i],
          );
        }
        stats.appended += appends.length;
      }

      await db.query(`delete from sheet_outbox where id = any($1)`, [group.ids]);
    } catch (err) {
      const message = String(err?.message ?? err).slice(0, 500);
      await db.query(
        `update sheet_outbox
         set last_error = $2, next_attempt_at = now() + ($3::int * interval '1 second')
         where id = any($1)`,
        [group.ids, message, retryDelaySeconds(group.attempts)],
      );
      stats.failedTables.push({ table, error: message });
    }
  }
  return stats;
}

/** Queue every existing row of the given tables (first sync, or a full resend). */
export async function enqueueBackfill(db, tables = MIRRORED_TABLES) {
  const counts = {};
  for (const table of tables) {
    if (!MIRRORED_TABLES.includes(table)) throw new Error(`${table} is not a mirrored table`);
    const { rows } = await db.query(
      `insert into sheet_outbox (table_name, row_pk, op)
       select $1, id::text, 'BACKFILL' from ${quoteIdent(table)} returning id`,
      [table],
    );
    counts[table] = rows.length;
  }
  return counts;
}

/**
 * Rebuild the row index for a tab from its id column. Use after someone edits
 * the mirror by hand. The last occurrence of a duplicated id wins, and the
 * duplicates are returned so they can be cleaned up.
 */
export async function rebuildIndex({ db, sheets, table }) {
  if (!MIRRORED_TABLES.includes(table)) throw new Error(`${table} is not a mirrored table`);
  const ids = await sheets.readColumnA(table);
  const seen = new Map();
  const duplicates = [];
  ids.forEach((id, i) => {
    const pk = String(id ?? "").trim();
    if (!pk) return;
    if (seen.has(pk)) duplicates.push(pk);
    seen.set(pk, i + 2); // column A values start at row 2
  });
  await db.query(`delete from sheet_row_index where table_name = $1`, [table]);
  for (const [pk, row] of seen) {
    await db.query(`insert into sheet_row_index (table_name, row_pk, row_number) values ($1,$2,$3)`, [table, pk, row]);
  }
  return { indexed: seen.size, duplicates };
}

/** What is waiting, per table, and the most recent error. */
export async function outboxStatus(db) {
  const { rows } = await db.query(
    `select table_name, count(*)::int as pending, max(attempts)::int as max_attempts,
            min(enqueued_at) as oldest, max(last_error) as last_error
     from sheet_outbox group by table_name order by table_name`,
  );
  return rows;
}

function quoteIdent(name) {
  if (!/^[a-z_][a-z0-9_]*$/.test(name)) throw new Error(`Unsafe identifier: ${name}`);
  return `"${name}"`;
}
