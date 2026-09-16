import { Pool, type PoolClient, type QueryResultRow } from "pg";

const connectionString = process.env.DATABASE_URL;

export const pool = connectionString ? new Pool({ connectionString, max: 5 }) : null;

export const isDbConfigured = Boolean(connectionString);

export async function query<T extends QueryResultRow = QueryResultRow>(text: string, params?: unknown[]): Promise<T[]> {
  if (!pool) throw new Error("DATABASE_URL not configured");
  const res = await pool.query(text, params);
  return res.rows;
}

export async function queryOne<T extends QueryResultRow = QueryResultRow>(text: string, params?: unknown[]): Promise<T | null> {
  const rows = await query<T>(text, params);
  return rows[0] ?? null;
}

/** Query surface bound to one transaction's connection. */
export interface Tx {
  query<T extends QueryResultRow = QueryResultRow>(text: string, params?: unknown[]): Promise<T[]>;
  queryOne<T extends QueryResultRow = QueryResultRow>(text: string, params?: unknown[]): Promise<T | null>;
}

function bind(client: PoolClient): Tx {
  return {
    async query<T extends QueryResultRow>(text: string, params?: unknown[]) {
      return (await client.query<T>(text, params)).rows;
    },
    async queryOne<T extends QueryResultRow>(text: string, params?: unknown[]): Promise<T | null> {
      return (await client.query<T>(text, params)).rows[0] ?? null;
    },
  };
}

/** Run fn in a single transaction: all of its writes commit, or none do. */
export async function withTransaction<T>(fn: (tx: Tx) => Promise<T>): Promise<T> {
  if (!pool) throw new Error("DATABASE_URL not configured");
  const client = await pool.connect();
  try {
    await client.query("begin");
    const result = await fn(bind(client));
    await client.query("commit");
    return result;
  } catch (e) {
    await client.query("rollback").catch(() => {});
    throw e;
  } finally {
    client.release();
  }
}
