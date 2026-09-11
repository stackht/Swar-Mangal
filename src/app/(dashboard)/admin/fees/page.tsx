"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Download, FilePlus2 } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { StatCard } from "@/components/dashboard/stat-card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

import { invoices, payments, students } from "@/lib/data/demo";
import type { Invoice } from "@/types";

export default function AdminFeesPage() {
  const [inv, setInv] = React.useState<Invoice[]>(invoices);
  const [amount, setAmount] = React.useState("120");
  const [selectedStudent, setSelectedStudent] = React.useState(students[0].id);

  const outstanding = inv.reduce((s, i) => (i.status !== "paid" ? s + Number(i.amount) : s), 0);
  const collected = payments.reduce((s, p) => s + p.amount, 0);

  const createInvoice = () => {
    const student = students.find((s) => s.id === selectedStudent)!;
    setInv((prev) => [
      {
        id: `inv-${Date.now()}`,
        student_id: selectedStudent,
        student_name: student.full_name,
        amount: Number(amount),
        status: "pending",
        due_date: new Date(Date.now() + 14 * 864e5).toISOString(),
        issued_date: new Date().toISOString(),
        description: "Monthly tuition",
      },
      ...prev,
    ]);
    toast.success("Invoice created");
  };

  const markPaid = (id: string) => {
    setInv((prev) => prev.map((i) => (i.id === id ? { ...i, status: "paid" as const } : i)));
    toast.success("Payment recorded");
  };

  return (
    <div>
      <PageHeader
        title="Fees & Payments"
        subtitle="Manage invoices and payments."
        actions={
          <Dialog>
            <DialogTrigger asChild>
              <Button><FilePlus2 className="h-4 w-4" /> New invoice</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Create invoice</DialogTitle>
                <DialogDescription>Bill a student for tuition.</DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label>Student</Label>
                  <select className="flex h-11 w-full rounded-2xl border bg-background px-4 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" value={selectedStudent} onChange={(e) => setSelectedStudent(e.target.value)}>
                    {students.map((s) => <option key={s.id} value={s.id}>{s.full_name}</option>)}
                  </select>
                </div>
                <div className="space-y-2">
                  <Label>Amount ($)</Label>
                  <Input type="number" value={amount} onChange={(e) => setAmount(e.target.value)} />
                </div>
                <Button className="w-full" onClick={createInvoice}>Create invoice</Button>
              </div>
            </DialogContent>
          </Dialog>
        }
      />

      <div className="mb-8 grid gap-4 sm:grid-cols-3">
        <StatCard label="Outstanding" value={`$${outstanding}`} icon={Download} accent="peach" />
        <StatCard label="Collected" value={`$${collected}`} icon={Download} accent="mint" />
        <StatCard label="Open invoices" value={inv.filter((i) => i.status === "pending").length} icon={Download} accent="lavender" />
      </div>

      <section className="mb-8">
        <SectionHeader title="Invoices" />
        {/* Desktop table */}
        <div className="hidden overflow-hidden rounded-2xl border border-border/60 bg-card lg:block">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-secondary/40 text-left text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                <th className="px-5 py-3">Student</th>
                <th className="px-5 py-3">Description</th>
                <th className="px-5 py-3">Due</th>
                <th className="px-5 py-3">Amount</th>
                <th className="px-5 py-3">Status</th>
                <th className="px-5 py-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody>
              {inv.map((i, idx) => (
                <motion.tr key={i.id} initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} transition={{ delay: idx * 0.03 }} className="border-b border-border/50 last:border-0 hover:bg-secondary/40">
                  <td className="px-5 py-3 font-medium">{i.student_name}</td>
                  <td className="px-5 py-3 text-muted-foreground">{i.description}</td>
                  <td className="px-5 py-3 text-muted-foreground">{new Date(i.due_date).toLocaleDateString()}</td>
                  <td className="px-5 py-3 font-semibold">${i.amount}</td>
                  <td className="px-5 py-3">
                    <Badge variant={i.status === "paid" ? "mint" : i.status === "overdue" ? "peach" : "lavender"}>{i.status}</Badge>
                  </td>
                  <td className="px-5 py-3 text-right">
                    {i.status !== "paid" ? (
                      <Button size="sm" variant="secondary" onClick={() => markPaid(i.id)}>Mark paid</Button>
                    ) : (
                      <span className="text-xs text-muted-foreground">—</span>
                    )}
                  </td>
                </motion.tr>
              ))}
            </tbody>
          </table>
        </div>
        {/* Mobile cards */}
        <div className="space-y-3 lg:hidden">
          {inv.map((i, idx) => (
            <motion.div key={i.id} initial={{ opacity: 0, y: 8 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: idx * 0.03 }} className="rounded-2xl border border-border/60 bg-card p-4">
              <div className="flex items-center justify-between gap-3">
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold">{i.student_name}</p>
                  <p className="truncate text-xs text-muted-foreground">{i.description}</p>
                </div>
                <Badge variant={i.status === "paid" ? "mint" : i.status === "overdue" ? "peach" : "lavender"}>{i.status}</Badge>
              </div>
              <div className="mt-3 flex items-center justify-between border-t border-border/50 pt-3">
                <span className="text-xs text-muted-foreground">Due {new Date(i.due_date).toLocaleDateString()}</span>
                <span className="text-base font-bold">${i.amount}</span>
              </div>
              {i.status !== "paid" && (
                <Button size="sm" variant="secondary" className="mt-3 w-full" onClick={() => markPaid(i.id)}>Mark paid</Button>
              )}
            </motion.div>
          ))}
        </div>
        {inv.length === 0 && (
          <p className="rounded-2xl border border-dashed border-border/70 bg-secondary/30 p-10 text-center text-sm text-muted-foreground">No invoices yet.</p>
        )}
      </section>

      <section>
        <SectionHeader title="Payment history" />
        <div className="space-y-2">
          {payments.map((p, i) => (
            <motion.div key={p.id} initial={{ opacity: 0, y: 8 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.04 }} className="flex items-center gap-4 rounded-2xl border border-border/60 bg-card p-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-mint-100/70 text-mint-700 dark:bg-mint-500/15 dark:text-mint-300">
                <Download className="h-5 w-5" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium">{p.student_name}</p>
                <p className="text-xs text-muted-foreground">{p.method} · {new Date(p.date).toLocaleDateString()}</p>
              </div>
              <span className="font-bold text-mint-700 dark:text-mint-300">+${p.amount}</span>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  );
}