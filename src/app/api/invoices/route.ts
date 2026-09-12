import { NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { query, queryOne, isDbConfigured } from "@/lib/db";

export async function POST(request: Request) {
  if (!isDbConfigured) return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  const { student_id, amount, description } = await request.json();
  if (!student_id || !amount) return NextResponse.json({ error: "Missing fields" }, { status: 400 });

  const student = await queryOne<{ full_name: string }>("select full_name from students where id = $1", [student_id]);
  const id = `inv-${randomUUID()}`;
  await query(
    "insert into invoices (id, student_id, student_name, description, amount, status, issued_date, due_date) values ($1, $2, $3, $4, $5, 'pending', now(), now() + interval '14 days')",
    [id, student_id, student?.full_name ?? "", description ?? "Monthly tuition", amount],
  );
  return NextResponse.json({ ok: true, id });
}

export async function PATCH(request: Request) {
  if (!isDbConfigured) return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  const { id, status } = await request.json();
  if (!id || !status) return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  await query("update invoices set status = $1, updated_at = now() where id = $2", [status, id]);
  if (status === "paid") {
    const inv = await queryOne<{ student_name: string; amount: number }>("select student_name, amount from invoices where id = $1", [id]);
    if (inv) {
      await query(
        "insert into payments (id, invoice_id, student_name, amount, method, status) values ($1, $2, $3, $4, 'Card', 'paid')",
        [`pay-${randomUUID()}`, id, inv.student_name, inv.amount],
      );
    }
  }
  return NextResponse.json({ ok: true });
}