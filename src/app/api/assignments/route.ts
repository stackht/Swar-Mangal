import { NextResponse } from "next/server";
import { query } from "@/lib/db";
import { requireUser } from "@/lib/api-auth";

export async function PATCH(request: Request) {
  const guard = await requireUser(["student", "teacher"]);
  if (guard.denied) return guard.denied;
  const { id, status } = await request.json();
  if (!id || !status) return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  await query("update assignments set status = $1, updated_at = now() where id = $2", [status, id]);
  return NextResponse.json({ ok: true });
}