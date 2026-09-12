import { NextResponse } from "next/server";
import { query, isDbConfigured } from "@/lib/db";

export async function PATCH(request: Request) {
  if (!isDbConfigured) return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  const { id, status } = await request.json();
  if (!id || !status) return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  await query("update assignments set status = $1, updated_at = now() where id = $2", [status, id]);
  return NextResponse.json({ ok: true });
}