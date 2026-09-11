"use client";

import { motion } from "framer-motion";
import { Clock3, ShieldCheck, UserCheck } from "lucide-react";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { StatCard } from "@/components/dashboard/stat-card";
import { cn } from "@/lib/utils/cn";

import { attendance } from "@/lib/data/demo";
import type { AttendanceStatus } from "@/types";

const meta: Record<AttendanceStatus, string> = {
  present: "bg-mint-100 text-mint-800 dark:bg-mint-500/15 dark:text-mint-300",
  absent: "bg-peach-100 text-peach-800 dark:bg-peach-500/15 dark:text-peach-300",
  late: "bg-lavender-100 text-lavender-800 dark:bg-lavender-500/15 dark:text-lavender-300",
  excused: "bg-secondary text-muted-foreground",
};

export default function ParentAttendancePage() {
  const mine = attendance.filter((a) => a.student_id === "s1");
  const pct = mine.length ? Math.round((mine.filter((a) => a.status === "present" || a.status === "late").length / mine.length) * 100) : 100;

  return (
    <div>
      <PageHeader title="Attendance" subtitle="Aarav's lesson attendance." />
      <div className="mb-8 grid gap-4 sm:grid-cols-3">
        <StatCard label="Attendance rate" value={`${pct}%`} icon={ShieldCheck} accent="mint" />
        <StatCard label="Present" value={mine.filter((a) => a.status === "present").length} icon={UserCheck} accent="lavender" />
        <StatCard label="Late" value={mine.filter((a) => a.status === "late").length} icon={Clock3} accent="sky" />
      </div>
      <section>
        <SectionHeader title="History" />
        <div className="space-y-2">
          {mine.map((a, i) => (
            <motion.div key={a.id} initial={{ opacity: 0, y: 8 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.04 }} className="flex items-center gap-4 rounded-2xl border bg-card p-4 shadow-card">
              <UserCheck className="h-5 w-5 text-muted-foreground/50" />
              <div className="flex-1">
                <p className="text-sm font-medium">{new Date(a.date).toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" })}</p>
                <p className="text-xs text-muted-foreground">Piano Fundamentals</p>
              </div>
              <span className={cn("rounded-full px-3 py-1 text-xs font-medium", meta[a.status])}>{a.status}</span>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  );
}