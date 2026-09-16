import { NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { query } from "@/lib/db";
import { requireUser } from "@/lib/api-auth";

export async function POST(request: Request) {
  const guard = await requireUser(["teacher", "admin"]);
  if (guard.denied) return guard.denied;
  const { class_id, student_id, status, date, marked_by } = await request.json();
  if (!class_id || !student_id || !status) return NextResponse.json({ error: "Missing fields" }, { status: 400 });

  const id = `a-${randomUUID()}`;
  await query(
    `insert into attendance (id, class_id, student_id, status, date, marked_by)
     values ($1, $2, $3, $4, coalesce($5::timestamptz, now()), $6)
     on conflict (class_id, student_id, date) do update set status = excluded.status, marked_by = excluded.marked_by`,
    [id, class_id, student_id, status, date ?? null, marked_by ?? "t1"],
  );
  return NextResponse.json({ ok: true });
}