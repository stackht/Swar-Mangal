import { NextResponse } from "next/server";
import { queryOne, isDbConfigured } from "@/lib/db";
import { verifyPassword, createSession, setSessionCookie } from "@/lib/auth";

export async function POST(request: Request) {
  if (!isDbConfigured) {
    return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  }

  const { email, password } = await request.json();
  if (!email || !password) {
    return NextResponse.json({ error: "Email and password are required" }, { status: 400 });
  }

  const user = await queryOne<{ id: string; email: string; password_hash: string; role: string; full_name: string }>(
    "select id, email, password_hash, role, full_name from users where email = $1",
    [email],
  );

  if (!user || !verifyPassword(password, user.password_hash)) {
    return NextResponse.json({ error: "Invalid credentials" }, { status: 401 });
  }

  const token = await createSession(user.id);
  await setSessionCookie(token);

  return NextResponse.json({
    user: { id: user.id, email: user.email, role: user.role, full_name: user.full_name },
  });
}