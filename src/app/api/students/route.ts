import { NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { query, isDbConfigured } from "@/lib/db";

export async function POST(request: Request) {
  if (!isDbConfigured) return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  const { full_name, instrument, email, level } = await request.json();
  if (!full_name) return NextResponse.json({ error: "Missing name" }, { status: 400 });

  const id = `s-${randomUUID()}`;
  await query(
    "insert into students (id, full_name, email, instrument, level, fee_status) values ($1, $2, $3, $4, $5, 'pending')",
    [id, full_name, email ?? "", instrument ?? "Piano", level ?? "Beginner"],
  );
  return NextResponse.json({ ok: true, id });
}

export async function DELETE(request: Request) {
  if (!isDbConfigured) return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  const { id } = await request.json();
  if (!id) return NextResponse.json({ error: "Missing id" }, { status: 400 });
  await query("delete from students where id = $1", [id]);
  return NextResponse.json({ ok: true });
}