"use client";

import * as React from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowRight, CheckCircle2, CircleDollarSign } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useMutationRpc, useStaffBoot } from "@/lib/api/rpc-hooks";
import type { RpcEnvelope } from "@/lib/api/rpc-types";
import { useTokenAuth } from "@/lib/auth/token-auth";
import { fadeUp, listVariants } from "@/lib/motion";
import { todayISO } from "@/lib/utils/cn";

const CATEGORIES = ["Rent", "Salary", "Utilities", "Maintenance", "Instruments", "Marketing", "Travel", "Other"];

const selectCls =
  "flex h-11 w-full rounded-2xl border border-[#F7F2E8]/12 bg-[#0B0A10] px-4 text-sm text-[#F7F2E8] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D6A84F]/60";

interface DraftArg extends Record<string, unknown> {
  amount: number;
  category: string;
  payee: string;
  description: string;
  mode: string;
  sourceAccount: string;
  reference: string;
  expenseDate: string;
  reimbursementRequired: boolean;
  paidBy: string;
  notes: string;
  branch: string;
  clientIntentKey: string;
}

interface DraftResponse extends RpcEnvelope {
  draftId?: string;
  note?: string;
}

export default function StaffExpensesPage() {
  const { session } = useTokenAuth();
  const branches = session?.branches ?? [];
  const boot = useStaffBoot(branches.length === 1 ? branches[0] : undefined);
  const accounts = boot.data?.accounts ?? [];
  const modes = boot.data?.paymentModes?.length ? boot.data.paymentModes : ["Cash", "UPI", "Bank Transfer"];

  const [amount, setAmount] = React.useState("");
  const [category, setCategory] = React.useState(CATEGORIES[0]);
  const [payee, setPayee] = React.useState("");
  const [description, setDescription] = React.useState("");
  const [mode, setMode] = React.useState("Cash");
  const [account, setAccount] = React.useState("");
  const [reference, setReference] = React.useState("");
  const [expenseDate, setExpenseDate] = React.useState(todayISO());
  const [reimbursement, setReimbursement] = React.useState(false);
  const [paidBy, setPaidBy] = React.useState("");
  const [notes, setNotes] = React.useState("");
  const [branch, setBranch] = React.useState(branches.length === 1 ? branches[0] : "ALL");
  const [success, setSuccess] = React.useState<DraftResponse | null>(null);

  const intentRef = React.useRef(`EDRAFT-${Date.now()}`);

  const submit = useMutationRpc<DraftArg, DraftResponse>("api_staff_submitExpenseDraft", {
    onSuccess: (res) => {
      setSuccess(res);
      toast.success(res.note ?? "Sent to Sharvil for approval.");
      intentRef.current = `EDRAFT-${Date.now()}`;
    },
    onError: (err) => toast.error(err.message.replace(/\[.*\]$/, "") || "Could not send the expense."),
  });

  const amountNum = Number(amount);
  const valid =
    Number.isFinite(amountNum) &&
    amountNum > 0 &&
    payee.trim().length > 0 &&
    (!reimbursement || paidBy.trim().length > 0);

  const reset = () => {
    setAmount("");
    setPayee("");
    setDescription("");
    setAccount("");
    setReference("");
    setNotes("");
    setPaidBy("");
    setReimbursement(false);
    setSuccess(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!valid) return;
    submit.mutate({
      amount: amountNum,
      category: category.trim(),
      payee: payee.trim(),
      description: description.trim() || payee.trim(),
      mode,
      sourceAccount: account.trim(),
      reference: reference.trim(),
      expenseDate,
      reimbursementRequired: reimbursement,
      paidBy: paidBy.trim(),
      notes: notes.trim(),
      branch,
      clientIntentKey: intentRef.current,
    });
  };

  return (
    <motion.div initial="hidden" animate="visible" variants={listVariants} className="mx-auto max-w-2xl space-y-5">
      <motion.div variants={fadeUp}>
        <p className="text-xs uppercase tracking-[0.16em] text-[#F7F2E8]/40">Staff · Money</p>
        <h1 className="mt-1 text-2xl font-semibold tracking-tight text-[#F7F2E8]">Submit Expense</h1>
        <p className="mt-1 text-sm text-[#F7F2E8]/55">
          Send an expense to Sharvil — he approves it and posts it to the cashbook.
        </p>
      </motion.div>

      {success && (
        <motion.div variants={fadeUp}>
          <Card className="border-emerald-400/30 bg-emerald-400/5">
            <CardContent className="flex flex-wrap items-center gap-3 pt-5 text-sm text-emerald-300">
              <CheckCircle2 className="h-5 w-5" aria-hidden />
              <span>{success.note ?? "Sent to Sharvil for approval."}</span>
              {success.draftId && <span className="font-mono text-xs text-emerald-200/70">{success.draftId}</span>}
              <Button asChild size="sm" variant="outline" className="ml-auto border-[#F7F2E8]/15 text-[#F7F2E8] hover:bg-white/[0.05]">
                <Link href="/staff/requests">
                  My requests <ArrowRight className="h-3.5 w-3.5" aria-hidden />
                </Link>
              </Button>
            </CardContent>
          </Card>
        </motion.div>
      )}

      <motion.form variants={fadeUp} onSubmit={handleSubmit} className="space-y-4">
        <Card className="border-[#F7F2E8]/10 bg-[#17131D]">
          <CardContent className="space-y-4 pt-5">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label className="text-[#F7F2E8]/70">Amount (₹)</Label>
                <Input
                  type="number"
                  min="1"
                  inputMode="decimal"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="e.g. 4000"
                  className="border-[#F7F2E8]/12 bg-[#0B0A10] text-[#F7F2E8] placeholder:text-[#F7F2E8]/30"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-[#F7F2E8]/70">Category</Label>
                <select className={selectCls} value={category} onChange={(e) => setCategory(e.target.value)}>
                  {CATEGORIES.map((c) => (
                    <option key={c} value={c}>
                      {c}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="space-y-2">
              <Label className="text-[#F7F2E8]/70">Paid to / what for</Label>
              <Input
                value={payee}
                onChange={(e) => setPayee(e.target.value)}
                placeholder="e.g. Stationery shop"
                className="border-[#F7F2E8]/12 bg-[#0B0A10] text-[#F7F2E8] placeholder:text-[#F7F2E8]/30"
              />
            </div>

            <div className="space-y-2">
              <Label className="text-[#F7F2E8]/70">Description</Label>
              <Input
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Optional — defaults to who was paid"
                className="border-[#F7F2E8]/12 bg-[#0B0A10] text-[#F7F2E8] placeholder:text-[#F7F2E8]/30"
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label className="text-[#F7F2E8]/70">Paid from (account)</Label>
                <Input
                  value={account}
                  onChange={(e) => setAccount(e.target.value)}
                  list="staff-accounts"
                  placeholder="Cash / UPI / bank"
                  className="border-[#F7F2E8]/12 bg-[#0B0A10] text-[#F7F2E8] placeholder:text-[#F7F2E8]/30"
                />
                <datalist id="staff-accounts">
                  {accounts.map((a) => (
                    <option key={a} value={a} />
                  ))}
                </datalist>
              </div>
              <div className="space-y-2">
                <Label className="text-[#F7F2E8]/70">Payment mode</Label>
                <select className={selectCls} value={mode} onChange={(e) => setMode(e.target.value)}>
                  {modes.map((m) => (
                    <option key={m} value={m}>
                      {m}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label className="text-[#F7F2E8]/70">Expense date</Label>
                <Input
                  type="date"
                  value={expenseDate}
                  max={todayISO()}
                  onChange={(e) => setExpenseDate(e.target.value)}
                  className="border-[#F7F2E8]/12 bg-[#0B0A10] text-[#F7F2E8]"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-[#F7F2E8]/70">Branch</Label>
                <select className={selectCls} value={branch} onChange={(e) => setBranch(e.target.value)}>
                  <option value="ALL">Academy-level</option>
                  {branches.map((b) => (
                    <option key={b} value={b}>
                      {b}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="space-y-2">
              <Label className="text-[#F7F2E8]/70">Reference / UTR (optional)</Label>
              <Input
                value={reference}
                onChange={(e) => setReference(e.target.value)}
                placeholder="Bank transfer ref, bill number…"
                className="border-[#F7F2E8]/12 bg-[#0B0A10] text-[#F7F2E8] placeholder:text-[#F7F2E8]/30"
              />
            </div>

            <div className="rounded-2xl border border-[#F7F2E8]/10 bg-white/[0.02] p-4">
              <label className="flex items-center gap-3 text-sm text-[#F7F2E8]/80">
                <input
                  type="checkbox"
                  checked={reimbursement}
                  onChange={(e) => setReimbursement(e.target.checked)}
                  className="h-4 w-4 rounded border-[#F7F2E8]/20 bg-[#0B0A10] accent-[#D6A84F]"
                />
                I paid this myself and need reimbursement
              </label>
              {reimbursement && (
                <div className="mt-3 space-y-1.5">
                  <Label className="text-[13px] text-[#F7F2E8]/70">Paid by *</Label>
                  <Input
                    value={paidBy}
                    onChange={(e) => setPaidBy(e.target.value)}
                    placeholder="Your name"
                    className="border-[#F7F2E8]/12 bg-[#0B0A10] text-[#F7F2E8] placeholder:text-[#F7F2E8]/30"
                  />
                </div>
              )}
            </div>

            <div className="space-y-2">
              <Label className="text-[#F7F2E8]/70">Notes (optional)</Label>
              <Textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Anything Sharvil should know"
                className="border-[#F7F2E8]/12 bg-[#0B0A10] text-[#F7F2E8] placeholder:text-[#F7F2E8]/30"
              />
            </div>
          </CardContent>
        </Card>

        <div className="flex flex-col-reverse gap-2 sm:flex-row sm:items-center sm:justify-between">
          <button
            type="button"
            onClick={reset}
            className="text-center text-sm text-[#F7F2E8]/60 transition-colors hover:text-[#F7F2E8]"
          >
            Clear
          </button>
          <Button type="submit" loading={submit.isPending} disabled={!valid} className="bg-[#D6A84F] text-[#08070B] hover:bg-[#E2BD68]">
            <CircleDollarSign className="h-4 w-4" aria-hidden />
            Send for approval
          </Button>
        </div>
      </motion.form>
    </motion.div>
  );
}
