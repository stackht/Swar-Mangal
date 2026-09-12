import { NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { query, isDbConfigured } from "@/lib/db";

export async function POST(request: Request) {
  if (!isDbConfigured) return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  const { student_id, instrument, activity, minutes } = await request.json();
  if (!student_id || !activity || !minutes) return NextResponse.json({ error: "Missing fields" }, { status: 400 });

  const id = `p-${randomUUID()}`;
  await query(
    "insert into practice_sessions (id, student_id, instrument, activity, minutes, goal_met) values ($1, $2, $3, $4, $5, $6)",
    [id, student_id, instrument ?? "Piano", activity, minutes, minutes >= 20],
  );
  return NextResponse.json({ ok: true, id });
}