"use client";

import { motion } from "framer-motion";
import { CreditCard, Download, FileText } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { StatCard } from "@/components/dashboard/stat-card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function StudentPaymentsPage() {
  const { invoices } = useAcademyData();
  const mine = invoices.filter((i) => i.student_id === "s1");
  const balance = invoices.filter((i) => i.status !== "paid").reduce((s, i) => s + Number(i.amount), 0);

  return (
    <div>
      <PageHeader title="Payments" subtitle="Fees and invoices." />

      <div className="mb-8 grid gap-4 sm:grid-cols-3">
        <StatCard label="Outstanding" value={`$${balance}`} icon={CreditCard} accent="peach" />
        <StatCard label="Paid to date" value={`$${invoices.filter((i) => i.status === "paid").reduce((s, i) => s + Number(i.amount), 0)}`} icon={FileText} accent="mint" />
        <StatCard label="Invoices" value={mine.length} icon={FileText} accent="lavender" />
      </div>

      <section>
        <SectionHeader title="Invoices" />
        <div className="space-y-3">
          {mine.map((inv, i) => (
            <motion.div
              key={inv.id}
              initial={{ opacity: 0, y: 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.05 }}
              className="flex flex-wrap items-center gap-4 rounded-3xl border bg-card p-5 shadow-card"
            >
              <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-lavender-100 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300">
                <FileText className="h-5 w-5" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold">{inv.description}</p>
                <p className="text-xs text-muted-foreground">
                  Issued {new Date(inv.issued_date).toLocaleDateString()} Ã‚Â· Due {new Date(inv.due_date).toLocaleDateString()}
                </p>
              </div>
              <span className="text-lg font-bold">${inv.amount}</span>
              <Badge
                variant={inv.status === "paid" ? "mint" : inv.status === "overdue" ? "peach" : "lavender"}
              >
                {inv.status}
              </Badge>
              {inv.status === "pending" && (
                <Button size="sm" onClick={() => toast.success("Payment gateway redirect (demo)")}>
                  Pay now
                </Button>
              )}
              <Button variant="ghost" size="icon" aria-label="Download invoice" onClick={() => toast.success("Downloading invoice")}>
                <Download className="h-4 w-4" />
              </Button>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  );
}