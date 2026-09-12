"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { CalendarDays, Flame, Music, Plus, Target } from "lucide-react";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { StatCard } from "@/components/dashboard/stat-card";
import { GradientCard } from "@/components/dashboard/gradient-card";
import { PracticeTimer } from "@/components/practice/practice-timer";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { toast } from "sonner";

import { useAcademyData } from "@/hooks/use-academy-data";

const activities = ["Scales & Arpeggios", "Sight Reading", "Repertoire", "Warm-up Exercises", "Ear Training"];

export default function StudentPracticePage() {
  const { practice, weeklyHours, refetch, isDemo, currentStudentId } = useAcademyData();
  const [activity, setActivity] = React.useState(activities[0]);
  const [sessions, setSessions] = React.useState(practice);
  const [minutes, setMinutes] = React.useState("");

  const goal = 150;
  const max = Math.max(...weeklyHours, 1);

  const submitSession = async (mins: number) => {
    if (!isDemo) {
      await fetch("/api/practice", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ student_id: currentStudentId, instrument: "Piano", activity, minutes: mins }),
      });
      await refetch();
    }
    setSessions((prev) => [
      { id: `p-${Date.now()}`, student_id: currentStudentId, instrument: "Piano", activity, minutes: mins, date: new Date().toISOString(), goal_met: mins >= 20 },
      ...prev,
    ]);
  };

  const handleComplete = (sec: number) => {
    const mins = sec > 0 ? Math.max(1, Math.round(sec / 60)) : 0;
    if (mins > 0) submitSession(mins);
  };

  const handleManual = async () => {
    const n = Number(minutes);
    if (!n || n <= 0) {
      toast.error("Enter a minute count");
      return;
    }
    await submitSession(n);
    setMinutes("");
    toast.success("Session logged");
  };

  return (
    <div>
      <PageHeader title="Practice" subtitle="Build your daily routine and track your progress." />

      <div className="mb-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Today" value={`${sessions.filter((s) => new Date(s.date).toDateString() === new Date().toDateString()).reduce((x, p) => x + p.minutes, 0)} min`} icon={CalendarDays} accent="lavender" />
        <StatCard label="This week" value={`${weeklyHours.reduce((a, b) => a + b, 0)} min`} icon={Music} accent="mint" hint={`${Math.round((weeklyHours.reduce((a, b) => a + b, 0) / goal) * 100)}% of goal`} />
        <StatCard label="Streak" value="3 days" icon={Flame} accent="peach" />
        <StatCard label="Total sessions" value={sessions.length} icon={Target} accent="sky" />
      </div>

      <div className="mb-8 grid gap-6 lg:grid-cols-2">
        <div className="space-y-4">
          <SectionHeader title="Start a session" subtitle="Pick an activity and press play" />
          <Card>
            <CardContent className="p-5">
              <div className="mb-4 flex flex-wrap gap-2">
                {activities.map((a) => (
                  <button
                    key={a}
                    onClick={() => setActivity(a)}
                    className={`rounded-full px-4 py-1.5 text-sm font-medium transition-all ${
                      activity === a ? "bg-primary text-primary-foreground" : "bg-secondary text-muted-foreground hover:text-foreground"
                    }`}
                  >
                    {a}
                  </button>
                ))}
              </div>
              <PracticeTimer instrument="Piano" activity={activity} onComplete={handleComplete} />

              <div className="mt-6 flex items-center gap-2 border-t pt-5">
                <Input type="number" placeholder="Or log minutes manually" value={minutes} onChange={(e) => setMinutes(e.target.value)} min={1} />
                <Button onClick={handleManual}><Plus className="h-4 w-4" /> Log</Button>
              </div>
            </CardContent>
          </Card>
        </div>

        <div>
          <SectionHeader title="This week" subtitle="Minutes per day" />
          <GradientCard gradient="navy" className="h-full p-5">
            <div className="flex h-52 items-end justify-between gap-2">
              {weeklyHours.map((h, i) => (
                <div key={i} className="flex flex-1 flex-col items-center gap-2">
                  <motion.div
                    initial={{ height: 0 }}
                    whileInView={{ height: `${(h / max) * 100}%` }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6, delay: i * 0.05, ease: [0.22, 1, 0.36, 1] }}
                    className="w-full rounded-xl bg-gradient-to-t from-lavender-500/60 to-mint-400"
                    style={{ minHeight: h > 0 ? 12 : 2 }}
                  />
                  <span className="text-xs text-white/70">{["M", "T", "W", "T", "F", "S", "S"][i]}</span>
                </div>
              ))}
            </div>
          </GradientCard>
        </div>
      </div>

      <section>
        <SectionHeader title="Recent sessions" subtitle="Your practice history" />
        <div className="space-y-2">
          {sessions.slice(0, 8).map((s, i) => (
            <motion.div
              key={s.id}
              initial={{ opacity: 0, y: 8 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.03 }}
              className="flex items-center gap-4 rounded-2xl border bg-card p-4 shadow-card"
            >
              <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-lavender-100 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300">
                <Music className="h-5 w-5" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium">{s.activity}</p>
                <p className="text-xs text-muted-foreground">
                  {s.instrument} Ãƒâ€šÃ‚Â· {new Date(s.date).toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" })}
                </p>
              </div>
              <span className="text-sm font-semibold tabular-nums">{s.minutes} min</span>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  );
}