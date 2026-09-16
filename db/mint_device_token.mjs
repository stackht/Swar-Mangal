// Issue, list or revoke a device token.
//
//   node db/mint_device_token.mjs "Latika Pixel" OPS_USER KANDIVALI
//   node db/mint_device_token.mjs --list
//   node db/mint_device_token.mjs --revoke DEV-1758...
//
// The token is printed ONCE and never stored: only its SHA-256 goes in the
// database, so a leaked backup cannot be replayed against the gateway.
import { createHash, randomBytes } from "node:crypto";
import pg from "pg";

const { Client } = pg;
const ROLES = new Set(["FOUNDER_ADMIN", "OPS_USER"]);

function usage(msg) {
  if (msg) console.error(`\n${msg}`);
  console.error(`
Usage:
  node db/mint_device_token.mjs "<label>" <FOUNDER_ADMIN|OPS_USER> [BRANCHES] [email]
  node db/mint_device_token.mjs --list
  node db/mint_device_token.mjs --revoke <device-id>

BRANCHES is a comma-separated allow-list for staff devices, e.g. KANDIVALI
or GOREGAON,KANDIVALI. Omit it to fall back to RPC_STAFF_BRANCHES.
`);
  process.exit(1);
}

async function main() {
  if (!process.env.DATABASE_URL) usage("DATABASE_URL is not set.");
  const args = process.argv.slice(2);
  if (!args.length) usage();

  const client = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  await client.connect();
  try {
    if (args[0] === "--list") {
      const { rows } = await client.query(
        `select id, label, role, branches, created_at, last_used_at, revoked_at
         from device_tokens order by created_at`,
      );
      if (!rows.length) {
        console.log("No device tokens issued yet (the env tokens still work).");
        return;
      }
      for (const r of rows) {
        const state = r.revoked_at ? `REVOKED ${r.revoked_at.toISOString().slice(0, 10)}` : "active";
        const used = r.last_used_at ? r.last_used_at.toISOString().slice(0, 16).replace("T", " ") : "never used";
        console.log(`${r.id}  ${r.label}  ${r.role}  ${r.branches || "(role default)"}  ${state}  last: ${used}`);
      }
      return;
    }

    if (args[0] === "--revoke") {
      const id = args[1];
      if (!id) usage("Give the device id to revoke (see --list).");
      const { rowCount } = await client.query(
        `update device_tokens set revoked_at = now() where id = $1 and revoked_at is null`,
        [id],
      );
      console.log(rowCount ? `Revoked ${id}. That device is locked out immediately.` : `No active token with id ${id}.`);
      return;
    }

    const [label, role, branches = "", email = ""] = args;
    if (!label || !ROLES.has(role)) usage("Give a label and a valid role.");

    const token = randomBytes(32).toString("base64url");
    const id = `DEV-${Date.now().toString(36).toUpperCase()}`;
    await client.query(
      `insert into device_tokens (id, token_hash, role, label, email, branches)
       values ($1,$2,$3,$4,$5,$6)`,
      [id, createHash("sha256").update(token).digest("hex"), role, label, email || null, branches || null],
    );

    console.log(`\nDevice:  ${label}  (${id})`);
    console.log(`Role:    ${role}${branches ? `  Branches: ${branches}` : ""}`);
    console.log(`\nToken (shown once — paste it into the app, then close this):\n\n  ${token}\n`);
    console.log(`Revoke with:  node db/mint_device_token.mjs --revoke ${id}\n`);
  } finally {
    await client.end().catch(() => {});
  }
}

main().catch((err) => {
  console.error("FAILED:", err.message);
  process.exitCode = 1;
});
