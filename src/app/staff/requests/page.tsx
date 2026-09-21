"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { CheckCircle2, Clock, Inbox, XCircle } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useRpc } from "@/lib/api/rpc-hooks";
import type { RpcEnvelope } from "@/lib/api/rpc-types";
import { fadeUp, listVariants } from "@/lib/motion";
import { cn } from "@/lib/utils/cn";
import { formatINR, formatWhen } from "@/app/founder/_shared";

interface MyRequest {
  type: string;
  id: string;
  status: string;
  student: string;
  category: string;
  amount: string;
  when: string;
  decisionNote: string;
  backdated: boolean;
}

interface MyRequestsResponse extends RpcEnvelope {
  count: number;
  rows: MyRequest[];
  canApprove: boolean;
}

const TYPE_LABELS: Record<string, string> = {
  PAYMENT_DRAFT: "Fee payment",
  EXPENSE_DRAFT: "Expense",
  STUDENT_DRAFT: "Student",
  RECEIPT_CORRECTION: "Receipt correction",
  SCHOOL_INVOICE_DRAFT: "School invoice",
  TEACHER_ADD_REQUEST: "New teacher",
};

function statusStyle(status: string) {
  const s = (status ?? "").toUpperCase();
  if (s === "APPROVED" || s === "MERGED" || s === "FINALISED")
    return { label: "Approved", className: "border-emerald-400/30 bg-emerald-400/10 text-emerald-300", icon: CheckCircle2 };
  if (s === "REJECTED") return { label: "Rejected", className: "border-red-400/30 bg-red-400/10 text-red-300", icon: XCircle };
  return { label: "Pending", className: "border-amber-400/30 bg-amber-400/10 text-amber-300", icon: Clock };
}

export default function StaffRequestsPage() {
  const { data, isPending, error, refetch } = useRpc<MyRequestsResponse>("api_staff_listMyApprovals", undefined);
  const [tab, setTab] = React.useState("ALL");

  const rows = data?.rows ?? [];
  const pending = rows.filter((r) => !["APPROVED", "MERGED", "FINALISED", "REJECTED"].includes((r.status ?? "").toUpperCase()));
  const approved = rows.filter((r) => ["APPROVED", "MERGED", "FINALISED"].includes((r.status ?? "").toUpperCase()));
  const rejected = rows.filter((r) => (r.status ?? "").toUpperCase() === "REJECTED");

  const types = Array.from(new Set(rows.map((r) => r.type)));
  const filtered = tab === "ALL" ? rows : rows.filter((r) => r.type === tab);

  const cards = [
    { label: "Pending", value: pending.length, icon: Clock, tone: "text-amber-300" },
    { label: "Approved", value: approved.length, icon: CheckCircle2, tone: "text-emerald-300" },
    { label: "Rejected", value: rejected.length, icon: XCircle, tone: "text-red-300" },
  ];

  return (
    <motion.div initial="hidden" animate="visible" variants={listVariants} className="space-y-6">
      <motion.div variants={fadeUp}>
        <p className="text-xs uppercase tracking-[0.16em] text-[#F7F2E8]/40">Staff · Connect</p>
        <h1 className="mt-1 text-2xl font-semibold tracking-tight text-[#F7F2E8]">My Requests</h1>
        <p className="mt-1 text-sm text-[#F7F2E8]/55">
          Everything you have sent to Sharvil, and where it stands.
        </p>
      </motion.div>

      <motion.div variants={fadeUp} className="grid gap-3 sm:grid-cols-3">
        {cards.map((c) => (
          <Card key={c.label} className="border-[#F7F2E8]/10 bg-[#17131D]">
            <CardContent className="flex items-center gap-3 pt-5">
              <span className={cn("flex h-9 w-9 items-center justify-center rounded-xl bg-white/[0.05]", c.tone)}>
                <c.icon className="h-4 w-4" aria-hidden />
              </span>
              <div>
                <p className="text-xs text-[#F7F2E8]/45">{c.label}</p>
                <p className="text-lg font-semibold tracking-tight text-[#F7F2E8]">{c.value}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </motion.div>

      {error ? (
        <motion.div variants={fadeUp}>
          <p className="rounded-2xl border border-red-400/30 bg-red-400/10 p-6 text-sm text-red-300">
            {error.message?.replace(/\[.*\]$/, "") || "Could not load your requests."}{" "}
            <button type="button" onClick={() => refetch()} className="font-medium text-[#D6A84F]">
              Retry
            </button>
          </p>
        </motion.div>
      ) : isPending ? (
        <div className="space-y-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-16 bg-white/[0.04]" />
          ))}
        </div>
      ) : rows.length === 0 ? (
        <motion.div variants={fadeUp}>
          <div className="flex flex-col items-center rounded-2xl border border-dashed border-[#F7F2E8]/15 bg-white/[0.02] px-6 py-16 text-center">
            <Inbox className="mb-3 h-9 w-9 text-[#F7F2E8]/25" aria-hidden />
            <p className="text-sm font-medium text-[#F7F2E8]/75">Nothing sent yet</p>
            <p className="mt-1 max-w-xs text-xs text-[#F7F2E8]/40">
              Fee payments, expenses and student drafts you submit will show up here.
            </p>
          </div>
        </motion.div>
      ) : (
        <>
          <motion.div variants={fadeUp} className="flex gap-1.5 overflow-x-auto no-scrollbar">
            {[{ key: "ALL", label: "All" }, ...types.map((t) => ({ key: t, label: TYPE_LABELS[t] ?? t }))].map((t) => (
              <button
                key={t.key}
                type="button"
                onClick={() => setTab(t.key)}
                className={cn(
                  "shrink-0 rounded-full border px-3.5 py-1.5 text-xs font-medium transition-colors",
                  tab === t.key
                    ? "border-[#D6A84F]/50 bg-[#D6A84F]/15 text-[#D6A84F]"
                    : "border-[#F7F2E8]/10 text-[#F7F2E8]/60 hover:bg-white/[0.05] hover:text-[#F7F2E8]",
                )}
              >
                {t.label}
              </button>
            ))}
          </motion.div>

          <motion.div variants={fadeUp} className="overflow-hidden rounded-2xl border border-[#F7F2E8]/10 bg-[#17131D]">
            {filtered.length === 0 ? (
              <p className="px-4 py-10 text-center text-sm text-[#F7F2E8]/45">Nothing in this tab.</p>
            ) : (
              <ul className="divide-y divide-[#F7F2E8]/[0.06]">
                {filtered.map((r) => {
                  const tone = statusStyle(r.status);
                  const Icon = tone.icon;
                  return (
                    <li key={`${r.type}-${r.id}`} className="flex items-center gap-4 px-4 py-3.5 sm:px-5">
                      <span className="hidden h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#D6A84F]/10 text-[#D6A84F] sm:flex">
                        <Icon className="h-5 w-5" aria-hidden />
                      </span>
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-2">
                          <span className="text-sm font-semibold text-[#F7F2E8]">{r.student || TYPE_LABELS[r.type] || r.type}</span>
                          <Badge className={tone.className}>{tone.label}</Badge>
                          {r.backdated && <Badge variant="peach">Backdated</Badge>}
                        </div>
                        <p className="mt-0.5 truncate text-xs text-[#F7F2E8]/45">
                          {[TYPE_LABELS[r.type] ?? r.type, r.category, r.when ? formatWhen(r.when) : ""].filter(Boolean).join(" · ")}
                        </p>
                        {r.decisionNote && (
                          <p className="mt-1 truncate text-xs text-[#F7F2E8]/60">Note: {r.decisionNote}</p>
                        )}
                      </div>
                      {r.amount && (
                        <span className="shrink-0 text-sm font-semibold text-[#F7F2E8]">{formatINR(r.amount)}</span>
                      )}
                    </li>
                  );
                })}
              </ul>
            )}
          </motion.div>
        </>
      )}
    </motion.div>
  );
}
