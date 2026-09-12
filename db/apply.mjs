import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import pg from "pg";

const { Client } = pg;
const here = dirname(fileURLToPath(import.meta.url));

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
    const statements = seed
      .split(";")
      .map((s) => s.trim())
      .filter(Boolean);
    for (const stmt of statements) {
      try {
        await client.query(stmt);
      } catch (err) {
        console.error("seed FAILED:", err.message);
        console.error("SQL head:", stmt.replace(/\s+/g, " ").slice(0, 160));
        throw err;
      }
    }
    console.log("seed applied", statements.length, "statements");

    const r = await client.query(
      "select (select count(*) from students) as students, (select count(*) from classes) as classes, (select count(*) from users) as users",
    );
    console.log("counts", JSON.stringify(r.rows[0]));
  } catch (err) {
    console.error("APPLY FAILED", err.message, err.stack ? "" : "");
    process.exitCode = 1;
  } finally {
    if (client) await client.end().catch(() => {});
  }
}

main();