import { NextResponse } from "next/server";
import { query, isDbConfigured } from "@/lib/db";

export async function PATCH(request: Request) {
  if (!isDbConfigured) return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  const { id, read } = await request.json();
  if (!id || typeof read !== "boolean") return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  await query("update notifications set read = $1 where id = $2", [read, id]);
  return NextResponse.json({ ok: true });
}