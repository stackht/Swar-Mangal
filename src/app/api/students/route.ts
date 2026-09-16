import { NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { query } from "@/lib/db";
import { requireUser } from "@/lib/api-auth";

export async function POST(request: Request) {
  const guard = await requireUser(["admin"]);
  if (guard.denied) return guard.denied;
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
  const guard = await requireUser(["admin"]);
  if (guard.denied) return guard.denied;
  const { id } = await request.json();
  if (!id) return NextResponse.json({ error: "Missing id" }, { status: 400 });
  await query("delete from students where id = $1", [id]);
  return NextResponse.json({ ok: true });
}