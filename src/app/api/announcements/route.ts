import { NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { query, isDbConfigured } from "@/lib/db";

export async function POST(request: Request) {
  if (!isDbConfigured) return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  const { title, body, author, audience, pinned } = await request.json();
  if (!title) return NextResponse.json({ error: "Missing title" }, { status: 400 });

  const id = `an-${randomUUID()}`;
  await query(
    "insert into announcements (id, title, body, author, audience, pinned) values ($1, $2, $3, $4, $5, $6)",
    [id, title, body ?? "", author ?? "The Swar Mangal Team", audience ?? "All students", pinned ?? false],
  );
  return NextResponse.json({ ok: true, id });
}