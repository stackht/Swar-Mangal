import { NextResponse } from "next/server";
import { isDbConfigured } from "@/lib/db";
import { loadDataset } from "@/lib/db/queries";
import { requireUser } from "@/lib/api-auth";

export const dynamic = "force-dynamic";

export async function GET() {
  if (!isDbConfigured) return NextResponse.json({ data: null, demo: true });
  const guard = await requireUser();
  if (guard.denied) return guard.denied;
  const data = await loadDataset();
  return NextResponse.json({ data, demo: false });
}
