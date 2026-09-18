import { readFileSync } from "node:fs";
import { randomBytes } from "node:crypto";
import pg from "pg";

const { Client } = pg;

// ---------------------------------------------------------------- CSV parse
// Minimal RFC4180 parser: handles quoted fields, embedded commas/quotes/newlines.
function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = "";
  let inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') {
          field += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field += c;
      }
    } else if (c === '"') {
      inQuotes = true;
    } else if (c === ",") {
      row.push(field);
      field = "";
    } else if (c === "\r") {
      // skip; \n handles the line break
    } else if (c === "\n") {
      row.push(field);
      rows.push(row);
      row = [];
      field = "";
    } else {
      field += c;
    }
  }
  if (field.length || row.length) {
    row.push(field);
    rows.push(row);
  }
  return rows;
}

function newId(prefix) {
  return `${prefix}-${Date.now()}-${randomBytes(3).toString("hex").toUpperCase()}`;
}

// ------------------------------------------------------------ spam heuristics
const SPAM_MARKERS = [
  "bit.ly", "<a href", "http://", "https://", "hentai",
  "free tool that lets you", "get more exposure", "classified sites",
  "boost your visib", "wanted to pass this along", "dead leads",
  "dead emails", "wealth filter", "hulu, roku", "reaching out because we help",
  "found your site", "noticed your business", "noticed your website",
  "saw your website", "thought you might want this", "visited swarmangal.com",
  "quick note, found your site", "engaging video to explain",
  "designed you a new one for free", "profile page for your company",
  "does this business listing belong",
];

function looksLikeSpam(note) {
  const n = note.toLowerCase();
  return SPAM_MARKERS.some((m) => n.includes(m));
}

function isTestRow(name) {
  const n = name.trim().toLowerCase();
  return n === "smoke test" || n.startsWith("example:");
}

// Indian mobile: 10 digits, first digit 6-9. Strips +91/91/0 prefixes and
// non-digits first (source data mixes "+91...", "91...", stray leading 0s,
// and outright malformed 8-9 digit numbers from spam bots).
function normalizePhone(raw) {
  const digits = String(raw ?? "").replace(/\D/g, "");
  const last10 = digits.slice(-10);
  if (last10.length === 10 && /^[6-9]/.test(last10)) return last10;
  return null;
}

function normalizeBranch(raw) {
  const b = String(raw ?? "").trim().toLowerCase();
  if (!b || b === "-") return "";
  if (b.includes("goregaon") || b === "gmc") return "GOREGAON";
  if (b.includes("kandiv") || b.includes("kandw") || b === "kmc") return "KANDIVALI";
  return ""; // outstation / unrecognized — leave unassigned rather than guess
}

const SOURCE_MAP = {
  website: "Website",
  phonebook_enquiry: "Phonebook",
  call_for_class: "Call-for-class",
  imported_excel: "Imported",
  reactivation_old_student: "Former Student",
  walk_in: "Walk-in",
  phone: "Phone",
};

function normalizeStatus(raw) {
  const s = String(raw ?? "").trim().toLowerCase();
  if (s === "contacted") return "CONTACTED";
  return "OPEN";
}

function normalizeInstrument(raw) {
  const v = String(raw ?? "").trim();
  if (!v) return "";
  const map = {
    Bansuri: "Flute",
    Sitar: "Sitar",
  };
  return map[v] ?? v;
}

function toDateOrNull(raw) {
  const v = String(raw ?? "").trim();
  if (!v) return null;
  const d = v.slice(0, 10);
  return /^\d{4}-\d{2}-\d{2}$/.test(d) ? d : null;
}

// ------------------------------------------------------------------- main
async function main() {
  const args = process.argv.slice(2);
  const apply = args.includes("--apply");
  const fileArg = args.find((a) => !a.startsWith("--"));
  if (!fileArg) {
    console.error("Usage: node db/import_leads_csv.mjs <path-to-csv> [--apply]");
    console.error("Without --apply, this only prints a dry-run summary.");
    process.exit(1);
  }

  const text = readFileSync(fileArg, "utf8");
  const rows = parseCsv(text);
  const header = rows[0].map((h) => h.trim());
  const idx = (name) => header.indexOf(name);
  const col = {
    name: idx("Lead Name"),
    phone: idx("Phone"),
    instrument: idx("Instrument"),
    branch: idx("Branch"),
    source: idx("Source"),
    status: idx("Status"),
    nextFollowUp: idx("Next Follow-up"),
    lastContacted: idx("Last Contacted"),
    notes: idx("Last Note Summary"),
    createdAt: idx("Created At"),
  };

  const dataRows = rows.slice(1).filter((r) => r.length > 1 || r[0]);

  let skippedTest = 0;
  let skippedSpam = 0;
  let skippedNoPhone = 0;
  const candidates = [];

  for (const r of dataRows) {
    const name = (r[col.name] ?? "").trim();
    const notes = (r[col.notes] ?? "").trim();

    if (isTestRow(name)) {
      skippedTest++;
      continue;
    }
    if (looksLikeSpam(notes)) {
      skippedSpam++;
      continue;
    }
    const phone = normalizePhone(r[col.phone]);
    if (!phone) {
      skippedNoPhone++;
      continue;
    }

    const createdAt = toDateOrNull(r[col.createdAt]) ?? new Date().toISOString().slice(0, 10);
    const source = SOURCE_MAP[(r[col.source] ?? "").trim()] ?? "Imported";

    candidates.push({
      name: name || "(no name)",
      phone,
      instrument: normalizeInstrument(r[col.instrument]),
      branch: normalizeBranch(r[col.branch]),
      source,
      status: normalizeStatus(r[col.status]),
      notes,
      createdAt,
      lastContactedAt: toDateOrNull(r[col.lastContacted]),
    });
  }

  // Dedup by phone: keep the earliest createdAt (first time they enquired),
  // prefer a row that has an instrument filled in and the richest notes.
  const byPhone = new Map();
  for (const c of candidates) {
    const existing = byPhone.get(c.phone);
    if (!existing) {
      byPhone.set(c.phone, c);
      continue;
    }
    if (c.createdAt < existing.createdAt) existing.createdAt = c.createdAt;
    if (!existing.instrument && c.instrument) existing.instrument = c.instrument;
    if (!existing.branch && c.branch) existing.branch = c.branch;
    if (c.notes.length > existing.notes.length) existing.notes = c.notes;
    if (c.status === "CONTACTED") existing.status = "CONTACTED";
    if (c.lastContactedAt && (!existing.lastContactedAt || c.lastContactedAt > existing.lastContactedAt)) {
      existing.lastContactedAt = c.lastContactedAt;
    }
  }
  const deduped = [...byPhone.values()];

  console.log(`Parsed ${dataRows.length} rows`);
  console.log(`  skipped (test rows):        ${skippedTest}`);
  console.log(`  skipped (spam content):     ${skippedSpam}`);
  console.log(`  skipped (no usable phone):  ${skippedNoPhone}`);
  console.log(`  candidates after phone-dedup: ${deduped.length}`);
  const byInstrument = {};
  const bySource = {};
  for (const c of deduped) {
    byInstrument[c.instrument || "(no preference)"] = (byInstrument[c.instrument || "(no preference)"] || 0) + 1;
    bySource[c.source] = (bySource[c.source] || 0) + 1;
  }
  console.log("  by instrument:", byInstrument);
  console.log("  by source:", bySource);

  if (!apply) {
    console.log("\nDry run only — pass --apply with DATABASE_URL set to write these rows.");
    return;
  }

  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error("DATABASE_URL is not set — refusing to apply.");
    process.exit(1);
  }

  const client = new Client({ connectionString: databaseUrl, ssl: { rejectUnauthorized: false } });
  await client.connect();
  try {
    const existingPhones = new Set(
      (await client.query(`select phone from inquiries where phone is not null`)).rows.map((r) => r.phone),
    );
    // Skip a phone that already matches an active/former student — this
    // importer is for leads only, never a shadow copy of the student roster.
    const studentPhones = new Set(
      (await client.query(`select phone from students_acad where phone is not null`)).rows
        .map((r) => normalizePhone(r.phone))
        .filter(Boolean),
    );

    let inserted = 0;
    let skippedExisting = 0;
    let skippedStudent = 0;
    for (const c of deduped) {
      if (studentPhones.has(c.phone)) {
        skippedStudent++;
        continue;
      }
      if (existingPhones.has(c.phone)) {
        skippedExisting++;
        continue;
      }
      await client.query(
        `insert into inquiries (id, name, phone, instrument, branch, source, notes, status, created_at, last_contacted_at, updated_at)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,now())`,
        [newId("INQ"), c.name, c.phone, c.instrument, c.branch, c.source, c.notes, c.status, c.createdAt, c.lastContactedAt],
      );
      inserted++;
    }
    console.log(`\nInserted ${inserted} inquiries.`);
    console.log(`Skipped ${skippedExisting} already present by phone.`);
    console.log(`Skipped ${skippedStudent} that match a current/former student's phone.`);
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
