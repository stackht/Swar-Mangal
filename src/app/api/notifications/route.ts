import { NextResponse } from "next/server";
import { query } from "@/lib/db";
import { requireUser } from "@/lib/api-auth";

export async function PATCH(request: Request) {
  const guard = await requireUser();
  if (guard.denied) return guard.denied;
  const { id, read } = await request.json();
  if (!id || typeof read !== "boolean") return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  await query("update notifications set read = $1 where id = $2", [read, id]);
  return NextResponse.json({ ok: true });
}