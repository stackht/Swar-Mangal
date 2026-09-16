import { createHash, timingSafeEqual } from "crypto";

export type RpcRole = "FOUNDER_ADMIN" | "OPS_USER";

export interface RpcSession {
  role: RpcRole;
  email: string;
  name: string;
}

const FOUNDER_TOKEN = process.env.RPC_FOUNDER_TOKEN || "";
const STAFF_TOKEN = process.env.RPC_STAFF_TOKEN || "";

// Hash both sides so the comparison is constant-time and length-independent.
function tokenMatches(given: string, expected: string): boolean {
  if (!expected) return false;
  const a = createHash("sha256").update(given).digest();
  const b = createHash("sha256").update(expected).digest();
  return timingSafeEqual(a, b);
}

export function authenticateToken(token?: string | null): RpcSession | null {
  if (!token) return null;
  if (tokenMatches(token, FOUNDER_TOKEN)) {
    return { role: "FOUNDER_ADMIN", email: "sharvil87@gmail.com", name: "Sharvil Vaidya" };
  }
  if (tokenMatches(token, STAFF_TOKEN)) {
    return { role: "OPS_USER", email: "smmahavirnagar@gmail.com", name: "Latika" };
  }
  return null;
}

export function isFounder(session: RpcSession | null): boolean {
  return session?.role === "FOUNDER_ADMIN";
}

export function isStaff(session: RpcSession | null): boolean {
  return session?.role === "OPS_USER";
}