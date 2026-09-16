import { NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { query } from "@/lib/db";
import { requireUser } from "@/lib/api-auth";

export async function POST(request: Request) {
  const guard = await requireUser(["admin"]);
  if (guard.denied) return guard.denied;
  const { title, body, author, audience, pinned } = await request.json();
  if (!title) return NextResponse.json({ error: "Missing title" }, { status: 400 });

  const id = `an-${randomUUID()}`;
  await query(
    "insert into announcements (id, title, body, author, audience, pinned) values ($1, $2, $3, $4, $5, $6)",
    [id, title, body ?? "", author ?? "The Swar Mangal Team", audience ?? "All students", pinned ?? false],
  );
  return NextResponse.json({ ok: true, id });
}