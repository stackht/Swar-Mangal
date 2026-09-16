import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { createHash, randomBytes, scryptSync } from "node:crypto";
import pg from "pg";

const { Client } = pg;
const here = dirname(fileURLToPath(import.meta.url));

function hashPassword(password) {
  const salt = randomBytes(16).toString("hex");
  const hash = scryptSync(password, salt, 64).toString("hex");
  return `${salt}:${hash}`;
}

async function ensureUser(client, { email, password, role, fullName }) {
  const hash = hashPassword(password);
  const inserted = await client.query(
    `insert into users (email, password_hash, role) values ($1, $2, $3)
     on conflict (email) do update set password_hash = excluded.password_hash, role = excluded.role
     returning id`,
    [email, hash, role],
  );
  const userId = inserted.rows[0].id;
  await client.query(
    `insert into profiles (user_id, email, full_name, role) values ($1, $2, $3, $4)
     on conflict (user_id) do update set full_name = excluded.full_name, role = excluded.role`,
    [userId, email, fullName, role],
  );
  return userId;
}

async function main() {
  if (!process.env.DATABASE_URL) {
    console.log("APPLY SKIPPED — no DATABASE_URL, demo mode");
    return;
  }
  let client;
  try {
    client = new Client({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    });
    await client.connect();
    console.log("connected");

    const schema = readFileSync(join(here, "schema.sql"), "utf8");
    try {
      await client.query(schema);
    } catch (err) {
      console.error("schema FAILED:", err.message);
      if (err.position) {
        const at = Number(err.position);
        console.error("SQL around failure:", schema.slice(Math.max(0, at - 120), at + 160).replace(/\s+/g, " "));
      }
      throw err;
    }
    console.log("schema applied");

    const seed = readFileSync(join(here, "seed.sql"), "utf8");
    const seedStatements = seed
      .split(";")
      .map((s) => s.trim())
      .filter(Boolean);
    await runStatements(client, seedStatements, "seed");
    console.log("seed applied", seedStatements.length, "statements");

    const real = readFileSync(join(here, "academyos_import.sql"), "utf8");
    try {
      await client.query(real);
      console.log("academyos_import applied (single batch)");
    } catch (err) {
      console.error("academyos_import FAILED:", err.message);
      throw err;
    }

    // Login users — passwords from env (APPLY auto-creates/updates on each boot).
    const adminPw = process.env.ADMIN_PASSWORD || "Admin@123";
    const staffPw = process.env.STAFF_PASSWORD || "Staff@123";
    await ensureUser(client, { email: "admin@maestro.app", password: adminPw, role: "admin", fullName: "Academy Admin" });
    await ensureUser(client, { email: "staff@maestro.app", password: staffPw, role: "teacher", fullName: "Academy Staff" });
    console.log("users ensured (admin/staff, passwords from env)");

    // One-time QA cleanup: gateway endpoint smoke-test rows (Bipin Sanghavi)
    try {
      const cleaned = await client.query(
        `delete from payment_drafts where student_name ilike '%Bipin%' or student_name ilike '%QA RETEST%';
         delete from receipts where party_name ilike '%Bipin%' or party_name ilike '%QA RETEST%';
         delete from money_ledger where party_name ilike '%Bipin%' or party_name ilike '%QA RETEST%';
         delete from practice_sessions where activity = 'Kanak practice' or activity = 'Chord Practice';
         -- stale uniform 17:00–18:00 auto-seeded timetable rows (re-seeded with real slots)
         delete from timetable where start_time = '17:00' and end_time = '18:00' and id like 'TT-%';`,
      );
      console.log("qa cleanup applied");
    } catch {
      console.log("qa cleanup skipped (fresh db)");
    }

    const r = await client.query(
      "select (select count(*) from students) as students, (select count(*) from students_acad) as students_acad, (select count(*) from teachers_acad) as teachers_acad, (select count(*) from receipts) as receipts, (select count(*) from attendance_acad) as attendance, (select count(*) from inquiries) as inquiries",
    );
    console.log("counts", JSON.stringify(r.rows[0]));
  } catch (err) {
    console.error("APPLY FAILED", err.message, err.stack ? "" : "");
    process.exitCode = 1;
  } finally {
    if (client) await client.end().catch(() => {});
  }
}

async function runStatements(client, statements, label) {
  for (const stmt of statements) {
    try {
      await client.query(stmt);
    } catch (err) {
      console.error(label + " FAILED:", err.message);
      console.error("SQL head:", stmt.replace(/\s+/g, " ").slice(0, 180));
      throw err;
    }
  }
}

main();