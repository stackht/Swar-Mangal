import { createHash, randomBytes, scryptSync, timingSafeEqual } from "crypto";
import { cookies } from "next/headers";
import { query, queryOne, isDbConfigured } from "@/lib/db";
import type { Role } from "@/types";

const SESSION_COOKIE = "sm_session";
const SESSION_TTL_DAYS = 30;

export interface SessionUser {
  id: string;
  email: string;
  role: Role;
  full_name: string;
}

export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString("hex");
  const hash = scryptSync(password, salt, 64).toString("hex");
  return `${salt}:${hash}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [salt, hash] = stored.split(":");
  if (!salt || !hash) return false;
  const candidate = scryptSync(password, salt, 64) as Buffer;
  const known = Buffer.from(hash, "hex");
  return candidate.length === known.length && timingSafeEqual(candidate, known);
}

export function sha256(input: string): string {
  return createHash("sha256").update(input).digest("hex");
}

export function generateSessionToken(): string {
  return randomBytes(32).toString("hex");
}

export async function createSession(userId: string): Promise<string> {
  const token = generateSessionToken();
  const tokenHash = sha256(token);
  await query("insert into user_sessions (token_hash, user_id, expires_at) values ($1, $2, now() + interval '30 days')", [tokenHash, userId]);
  return token;
}

export async function setSessionCookie(token: string): Promise<void> {
  const store = await cookies();
  store.set(SESSION_COOKIE, token, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: SESSION_TTL_DAYS * 24 * 60 * 60,
  });
}

export async function clearSessionCookie(): Promise<void> {
  const store = await cookies();
  store.delete(SESSION_COOKIE);
}

export async function getCurrentUser(): Promise<SessionUser | null> {
  if (!isDbConfigured) return null;
  const store = await cookies();
  const token = store.get(SESSION_COOKIE)?.value;
  if (!token) return null;
  const row = await queryOne<{ user_id: string; expires_at: string }>(
    "select user_id, expires_at from user_sessions where token_hash = $1 and expires_at > now()",
    [sha256(token)],
  );
  if (!row) return null;
  const user = await queryOne<{ id: string; email: string; role: Role; full_name: string }>(
    `select u.id, u.email, u.role, coalesce(p.full_name, u.email) as full_name
     from users u left join profiles p on p.user_id = u.id where u.id = $1`,
    [row.user_id],
  );
  return user ?? null;
}