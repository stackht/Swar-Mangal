import { NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { query, isDbConfigured } from "@/lib/db";

export async function POST(request: Request) {
  if (!isDbConfigured) return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  const { thread_id, sender_id, sender_name, body } = await request.json();
  if (!thread_id || !sender_name || !body) return NextResponse.json({ error: "Missing fields" }, { status: 400 });

  const id = `m-${randomUUID()}`;
  await query(
    "insert into messages (id, thread_id, sender_id, sender_name, body) values ($1, $2, $3, $4, $5)",
    [id, thread_id, sender_id ?? null, sender_name, body],
  );
  await query("update message_threads set updated_at = now() where id = $1", [thread_id]);
  return NextResponse.json({ ok: true, id });
}