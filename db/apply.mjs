import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import pg from "pg";

const { Client } = pg;
const here = dirname(fileURLToPath(import.meta.url));

const connectionString =
  process.env.DATABASE_URL ||
  process.env.PGDATABASE_URL ||
  "postgresql://postgres:postgres@localhost:5432/swarmangal";

async function main() {
  if (!process.env.DATABASE_URL) {
    console.log("APPLY SKIPPED — no DATABASE_URL, demo mode");
    return;
  }
  let client;
  try {
    client = new Client({
      connectionString,
      ssl:
        connectionString.includes("railway.internal") ||
        connectionString.includes("up.railway.app")
          ? { rejectUnauthorized: false }
          : undefined,
    });
    await client.connect();
    console.log("connected");
    const schema = readFileSync(join(here, "schema.sql"), "utf8");
    await client.query(schema);
    console.log("schema applied");
    const seed = readFileSync(join(here, "seed.sql"), "utf8");
    await client.query(seed);
    console.log("seed applied");
    const r = await client.query(
      "select (select count(*) from students) as students, (select count(*) from classes) as classes, (select count(*) from users) as users",
    );
    console.log("counts", JSON.stringify(r.rows[0]));
  } catch (err) {
    console.error("APPLY FAILED", err.message);
    process.exitCode = 1;
  } finally {
    if (client) await client.end().catch(() => {});
  }
}

main();