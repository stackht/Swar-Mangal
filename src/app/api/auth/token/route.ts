import { cookies } from "next/headers";
import { NextRequest, NextResponse } from "next/server";
import { authenticateToken, type RpcSession } from "@/lib/rpc/auth";

const COOKIE = "sm_rpc_token";
const MAX_AGE = 30 * 24 * 60 * 60; // 30 days

/**
 * POST /api/auth/token — set a device token as an httpOnly cookie.
 * Body: { token: string, endpoint?: "founder" | "staff" }
 *
 * The raw token is NEVER returned to the client. The response contains only
 * the session info (role, email, name, branches) so the client knows who it is.
 */
export async function POST(req: NextRequest) {
  let body: { token?: string; endpoint?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid JSON" }, { status: 400 });
  }

  const token = body.token?.trim();
  if (!token) {
    return NextResponse.json({ ok: false, error: "Token required" }, { status: 400 });
  }

  const session = await authenticateToken(token);
  if (!session) {
    return NextResponse.json({ ok: false, code: "AUTH_FAILED", error: "Invalid or revoked token" }, { status: 401 });
  }

  // Verify the endpoint matches the role (optional guard).
  if (body.endpoint === "founder" && session.role !== "FOUNDER_ADMIN") {
    return NextResponse.json({ ok: false, code: "ROLE_FORBIDDEN", error: "This token is not a founder token" }, { status: 403 });
  }
  if (body.endpoint === "staff" && session.role !== "OPS_USER") {
    return NextResponse.json({ ok: false, code: "ROLE_FORBIDDEN", error: "This token is not a staff token" }, { status: 403 });
  }

  const store = await cookies();
  store.set(COOKIE, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: MAX_AGE,
  });

  // Return session info — never the token itself.
  return NextResponse.json({
    ok: true,
    role: session.role,
    email: session.email,
    name: session.name,
    branches: session.branches ?? [],
  });
}

/**
 * GET /api/auth/token — validate the current session cookie.
 * Returns session info or 401.
 */
export async function GET() {
  const store = await cookies();
  const token = store.get(COOKIE)?.value;
  if (!token) {
    return NextResponse.json({ ok: false, code: "AUTH_FAILED", error: "Not signed in" }, { status: 401 });
  }

  const session = await authenticateToken(token);
  if (!session) {
    // Token was revoked or DB is unreachable — clear the stale cookie.
    const res = NextResponse.json({ ok: false, code: "AUTH_FAILED", error: "Session expired" }, { status: 401 });
    res.cookies.set(COOKIE, "", { maxAge: 0, path: "/" });
    return res;
  }

  return NextResponse.json({
    ok: true,
    role: session.role,
    email: session.email,
    name: session.name,
    branches: session.branches ?? [],
  });
}

/**
 * DELETE /api/auth/token — clear the session cookie (logout).
 */
export async function DELETE() {
  const res = NextResponse.json({ ok: true });
  res.cookies.set(COOKIE, "", { maxAge: 0, path: "/" });
  return res;
}
