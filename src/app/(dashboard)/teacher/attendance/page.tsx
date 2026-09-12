"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Check, X, Clock3, ShieldQuestion } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { Avatar } from "@/components/ui/avatar";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils/cn";

import { useAcademyData } from "@/hooks/use-academy-data";
import type { AttendanceStatus } from "@/types";

const statuses: { key: AttendanceStatus; label: string; icon: React.ReactNode; activeCls: string }[] = [
  { key: "present", label: "Present", icon: <Check className="h-4 w-4" />, activeCls: "bg-mint-500 text-white" },
  { key: "absent", label: "Absent", icon: <X className="h-4 w-4" />, activeCls: "bg-peach-500 text-white" },
  { key: "late", label: "Late", icon: <Clock3 className="h-4 w-4" />, activeCls: "bg-lavender-500 text-white" },
  { key: "excused", label: "Excused", icon: <ShieldQuestion className="h-4 w-4" />, activeCls: "bg-secondary text-foreground" },
];

export default function TeacherAttendancePage() {
  const { classes, students, refetch, isDemo } = useAcademyData();
  const todayClasses = classes.filter((c) => c.teacher_id === "t1" && new Date(c.start_time).toDateString() === new Date().toDateString());
  const [activeClass, setActiveClass] = React.useState(todayClasses[0]?.id ?? todayClasses[0]?.id);
  const [marks, setMarks] = React.useState<Record<string, AttendanceStatus>>({});
  const [savedFor, setSavedFor] = React.useState<string | null>(null);

  const current = classes.find((c) => c.id === activeClass);
  const roster = current ? [...current.student_ids].map((id) => students.find((s) => s.id === id)!).filter(Boolean) : [];
  const allMarked = roster.length > 0 && roster.every((s) => marks[s.id]);

  const markAll = (status: AttendanceStatus) => {
    const next = { ...marks };
    roster.forEach((s) => (next[s.id] = status));
    setMarks(next);
  };

  const save = async () => {
    if (!allMarked) {
      toast.error("Mark attendance for every student first");
      return;
    }
    if (!isDemo) {
      await Promise.all(
        roster.map((s) =>
          fetch("/api/attendance", {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({
              class_id: activeClass,
              student_id: s.id,
              status: marks[s.id],
              date: new Date().toISOString(),
              marked_by: "t1",
            }),
          }),
        ),
      );
      await refetch();
    }
    setSavedFor(activeClass);
    toast.success("Attendance saved");
  };

  const reset = () => setMarks({});

  return (
    <div>
      <PageHeader title="Attendance" subtitle="Mark the roll for today's classes." />

      <div className="mb-6 flex gap-2 overflow-x-auto pb-1 no-scrollbar">
        {(todayClasses.length ? todayClasses : classes.filter((c) => c.teacher_id === "t1")).map((c) => (
          <button
            key={c.id}
            onClick={() => {
              setActiveClass(c.id);
              setSavedFor(null);
            }}
            className={cn(
              "shrink-0 rounded-2xl border px-4 py-2 text-sm font-medium transition-all",
              activeClass === c.id ? "border-transparent bg-primary text-primary-foreground shadow-soft" : "bg-card text-muted-foreground hover:text-foreground",
            )}
          >
            {c.title}
          </button>
        ))}
      </div>

      {current && (
        <Card>
          <CardContent className="p-5">
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="font-semibold">{current.title}</p>
                <p className="text-xs text-muted-foreground">
                  {current.student_ids.length} students Ã‚Â· {new Date(current.start_time).toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" })}
                </p>
              </div>
              <div className="flex gap-2">
                <Button variant="outline" size="sm" onClick={reset}>Reset</Button>
                <Button variant="secondary" size="sm" onClick={() => markAll("present")}>All present</Button>
                <Button size="sm" onClick={save}>{savedFor === activeClass ? "Saved Ã¢Å“â€œ" : "Save attendance"}</Button>
              </div>
            </div>

            <div className="mt-4 space-y-2">
              {roster.map((s, i) => (
                <motion.div
                  key={s.id}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.04 }}
                  className="flex flex-wrap items-center gap-4 rounded-2xl border bg-card p-3"
                >
                  <Avatar name={s.full_name} size="md" />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium">{s.full_name}</p>
                    <p className="text-xs text-muted-foreground">{s.instrument} Ã‚Â· {s.level}</p>
                  </div>
                  <div className="flex gap-1.5">
                    {statuses.map((st) => (
                      <button
                        key={st.key}
                        onClick={() => setMarks((prev) => ({ ...prev, [s.id]: st.key }))}
                        className={cn(
                          "flex items-center gap-1 rounded-xl px-3 py-1.5 text-xs font-medium transition-all",
                          marks[s.id] === st.key ? st.activeCls : "bg-secondary text-muted-foreground hover:text-foreground",
                        )}
                        aria-pressed={marks[s.id] === st.key}
                      >
                        {st.icon} {st.label}
                      </button>
                    ))}
                  </div>
                </motion.div>
              ))}
              {roster.length === 0 && (
                <p className="py-8 text-center text-sm text-muted-foreground">No students enrolled in this class.</p>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      <div className="mt-8">
        <SectionHeader title="Recent marks" />
        <div className="flex flex-wrap gap-3">
          {classes.filter((c) => c.teacher_id === "t1").slice(0, 3).map((c) => (
            <div key={c.id} className="flex items-center gap-2 rounded-2xl border bg-card px-4 py-2.5 shadow-card">
              <Badge variant="mint">Present</Badge>
              <span className="text-xs text-muted-foreground">{c.title}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}