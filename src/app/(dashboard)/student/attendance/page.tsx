"use client";

import { motion } from "framer-motion";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { StatCard } from "@/components/dashboard/stat-card";
import { ProgressRing } from "@/components/dashboard/progress-ring";
import { UserCheck, UserX, Clock3, ShieldCheck } from "lucide-react";
import { cn } from "@/lib/utils/cn";

import { useAcademyData } from "@/hooks/use-academy-data";
import type { AttendanceStatus } from "@/types";

const statusMeta: Record<AttendanceStatus, { label: string; cls: string }> = {
  present: { label: "Present", cls: "bg-mint-100 text-mint-800 dark:bg-mint-500/15 dark:text-mint-300" },
  absent: { label: "Absent", cls: "bg-peach-100 text-peach-800 dark:bg-peach-500/15 dark:text-peach-300" },
  late: { label: "Late", cls: "bg-lavender-100 text-lavender-800 dark:bg-lavender-500/15 dark:text-lavender-300" },
  excused: { label: "Excused", cls: "bg-secondary text-muted-foreground" },
};

export default function StudentAttendancePage() {
  const { attendance } = useAcademyData();
  const mine = attendance.filter((a) => a.student_id === "s1");
  const present = mine.filter((a) => a.status === "present").length;
  const late = mine.filter((a) => a.status === "late").length;
  const pct = mine.length ? Math.round(((present + late) / mine.length) * 100) : 100;

  return (
    <div>
      <PageHeader title="Attendance" subtitle="Your lesson attendance record." />

      <div className="mb-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Attendance rate" value={`${pct}%`} icon={ShieldCheck} accent="mint" />
        <StatCard label="Classes present" value={present} icon={UserCheck} accent="lavender" />
        <StatCard label="Late" value={late} icon={Clock3} accent="sky" />
        <StatCard label="Absent" value={mine.filter((a) => a.status === "absent").length} icon={UserX} accent="peach" />
      </div>

      <div className="mb-8 flex items-center gap-6 rounded-3xl border bg-card p-5 shadow-card">
        <ProgressRing value={pct} size={88} color="#2dbd7f" label={`${pct}%`} sublabel="rate" />
        <div>
          <p className="text-sm font-semibold">Great attendance!</p>
          <p className="text-xs text-muted-foreground">{`Keep it up and you'll hit your recital goals.`}</p>
        </div>
      </div>

      <section>
        <SectionHeader title="History" />
        <div className="space-y-2">
          {mine.map((a, i) => (
            <motion.div
              key={a.id}
              initial={{ opacity: 0, y: 8 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.03 }}
              className="flex items-center gap-4 rounded-2xl border bg-card p-4 shadow-card"
            >
              <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-secondary font-semibold text-sm">
                {new Date(a.date).toLocaleDateString(undefined, { day: "numeric" })}
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium">
                  {new Date(a.date).toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" })}
                </p>
                <p className="text-xs text-muted-foreground">Piano Fundamentals</p>
              </div>
              <span className={cn("rounded-full px-3 py-1 text-xs font-medium", statusMeta[a.status].cls)}>
                {statusMeta[a.status].label}
              </span>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  );
}