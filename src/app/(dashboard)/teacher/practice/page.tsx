"use client";

import { motion } from "framer-motion";
import { Music, Flame } from "lucide-react";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { StatCard } from "@/components/dashboard/stat-card";
import { Avatar } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function TeacherPracticePage() {
const { practice, students, classes, currentTeacherId } = useAcademyData();
  const rosterIds = new Set(classes.filter((c) => c.teacher_id === currentTeacherId).flatMap((c) => c.student_ids));
  const myStudents = students.filter((s) => rosterIds.has(s.id));

  const minsOf = (id: string, dayWindow: number) =>
    practice.filter((p) => p.student_id === id && new Date(p.date) >= new Date(Date.now() - dayWindow * 864e5)).reduce((x, p) => x + p.minutes, 0);

  const allThisWeek = practice.filter((p) => new Date(p.date) >= new Date(Date.now() - 7 * 864e5));

  return (
    <div>
      <PageHeader title="Practice Tracking" subtitle="Monitor your students' practice habits." />

      <div className="mb-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Sessions this week" value={allThisWeek.length} icon={Music} accent="lavender" />
        <StatCard label="Minutes logged" value={allThisWeek.reduce((x, p) => x + p.minutes, 0)} icon={Music} accent="mint" />
        <StatCard label="Avg / student" value={`${Math.round(allThisWeek.reduce((x, p) => x + p.minutes, 0) / Math.max(myStudents.length, 1))} min`} icon={Flame} accent="peach" />
        <StatCard label="On track" value={myStudents.filter((s) => minsOf(s.id, 7) >= 90).length} icon={Flame} accent="sky" />
      </div>

      <section>
        <SectionHeader title="Per student" subtitle="Practice minutes over the last 7 days" />
        <div className="space-y-3">
          {myStudents.map((s, i) => {
            const mins = minsOf(s.id, 7);
            const sessions = practice.filter((p) => p.student_id === s.id).slice(0, 3);
            const goal = 120;
            const onTrack = mins >= 90;
            return (
              <motion.div
                key={s.id}
                initial={{ opacity: 0, y: 10 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05 }}
                className="rounded-3xl border bg-card p-5 shadow-card"
              >
                <div className="flex items-center gap-3">
                  <Avatar name={s.full_name} />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold">{s.full_name}</p>
                    <p className="text-xs text-muted-foreground">{s.instrument}</p>
                  </div>
                  <Badge variant={onTrack ? "mint" : "peach"}>{onTrack ? "On track" : "Needs practice"}</Badge>
                  <span className="text-sm font-bold tabular-nums">{mins}/{goal} min</span>
                </div>
                <div className="mt-3">
                  <Progress value={Math.min(100, (mins / goal) * 100)} indicatorClassName={onTrack ? "bg-gradient-to-r from-mint-400 to-lavender-400" : "bg-gradient-to-r from-peach-400 to-lavender-400"} />
                </div>
                {sessions.length > 0 && (
                  <div className="mt-3 flex gap-2 overflow-x-auto no-scrollbar">
                    {sessions.map((p) => (
                      <span key={p.id} className="shrink-0 rounded-full bg-secondary px-3 py-1 text-xs text-muted-foreground">
                        {p.activity} � {p.minutes} min
                      </span>
                    ))}
                  </div>
                )}
              </motion.div>
            );
          })}
        </div>
      </section>
    </div>
  );
}