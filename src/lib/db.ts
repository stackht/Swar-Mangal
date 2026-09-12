import { Pool, type QueryResultRow } from "pg";

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