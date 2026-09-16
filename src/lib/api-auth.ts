import { NextResponse } from "next/server";
import { getCurrentUser, type SessionUser } from "@/lib/auth";
import { isDbConfigured } from "@/lib/db";
import type { Role } from "@/types";

type Guard = { user: SessionUser; denied?: never } | { user?: never; denied: NextResponse };

/**
 * Web-app route guard. Every /api/* route other than /api/rpc (token auth)
 * and /api/auth/* must call this before touching the database.
 * With no roles given, any signed-in user passes.
 */
export async function requireUser(roles?: Role[]): Promise<Guard> {
  if (!isDbConfigured) {
    return { denied: NextResponse.json({ error: "Database not configured" }, { status: 503 }) };
  }
  const user = await getCurrentUser();
  if (!user) {
    return { denied: NextResponse.json({ error: "Not signed in" }, { status: 401 }) };
  }
  if (roles && !roles.includes(user.role)) {
    return { denied: NextResponse.json({ error: "Forbidden" }, { status: 403 }) };
  }
  return { user };
}
