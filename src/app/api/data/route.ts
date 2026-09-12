import { NextResponse } from "next/server";
import { isDbConfigured } from "@/lib/db";
import { loadDataset } from "@/lib/db/queries";

export const dynamic = "force-dynamic";

export async function GET() {
  if (!isDbConfigured) return NextResponse.json({ data: null, demo: true });
  const data = await loadDataset();
  return NextResponse.json({ data, demo: false });
}