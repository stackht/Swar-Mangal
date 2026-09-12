"use client";

import { motion } from "framer-motion";
import { Clock, Flame, Trophy } from "lucide-react";
import { XAxis, YAxis, Tooltip, ResponsiveContainer, AreaChart, Area } from "recharts";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { GradientCard } from "@/components/dashboard/gradient-card";
import { ProgressRing } from "@/components/dashboard/progress-ring";
import { Progress } from "@/components/ui/progress";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function StudentProgressPage() {
  const { progress, feedback, achievements, skillCategories } = useAcademyData();
  const chartData = [
    { week: "W1", score: 52 },
    { week: "W2", score: 55 },
    { week: "W3", score: 58 },
    { week: "W4", score: 62 },
    { week: "W5", score: 60 },
    { week: "W6", score: 67 },
  ];

  return (
    <div>
      <PageHeader title="My Progress" subtitle="Your musical journey, measured." />

      <div className="mb-8 grid gap-6 lg:grid-cols-3">
        <GradientCard gradient="navy" className="flex items-center gap-5">
          <ProgressRing value={progress.overall} size={120} stroke={12} color="#8d6bf6" trackColor="rgba(255,255,255,0.15)" label={`${progress.overall}`} sublabel="overall" />
          <div>
            <p className="text-lg font-bold">{progress.level}</p>
            <p className="text-sm text-white/70">{progress.instrument}</p>
            <p className="mt-3 rounded-full bg-white/10 px-3 py-1 text-xs text-white/80">Level up in progress</p>
          </div>
        </GradientCard>

        <div className="rounded-2xl border border-border/60 bg-card p-5">
          <p className="text-eyebrow">Skill categories</p>
          <div className="mt-3 space-y-2.5">
            {progress.categories.slice(0, 5).map((c) => (
              <div key={c.name}>
                <div className="mb-1 flex justify-between text-xs">
                  <span className="text-muted-foreground">{c.name}</span>
                  <span className="tabular-nums font-medium">{c.score}</span>
                </div>
                <div className="h-1.5 overflow-hidden rounded-full bg-secondary">
                  <div className="h-full rounded-full bg-gradient-to-r from-lavender-500 to-mint-500" style={{ width: `${c.score}%` }} />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-2xl border border-border/60 bg-card p-5">
          <p className="text-eyebrow">Overall trend</p>
          <div className="mt-2 h-36">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="trend" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#8d6bf6" stopOpacity={0.5} />
                    <stop offset="100%" stopColor="#8d6bf6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <Area type="monotone" dataKey="score" stroke="#8d6bf6" strokeWidth={2.5} fill="url(#trend)" />
                <XAxis dataKey="week" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: "hsl(220 12% 46%)" }} />
                <YAxis hide domain={[0, 100]} />
                <Tooltip contentStyle={{ borderRadius: 16, border: "1px solid hsl(220 18% 90%)", fontSize: 12 }} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <section className="mb-8">
        <SectionHeader title="All skill areas" />
        <div className="grid gap-3 sm:grid-cols-2">
          {skillCategories.map((c, i) => (
            <motion.div
              key={c.name}
              initial={{ opacity: 0, y: 8 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.04 }}
              className="rounded-2xl border bg-card p-4 shadow-card"
            >
              <div className="mb-2 flex justify-between text-sm">
                <span className="font-medium">{c.name}</span>
                <span className="text-muted-foreground">{c.score}/100</span>
              </div>
              <Progress value={c.score} indicatorClassName="from-lavender-400 to-mint-400 bg-gradient-to-r" />
            </motion.div>
          ))}
        </div>
      </section>

      <div className="grid gap-6 lg:grid-cols-2">
        <section>
          <SectionHeader title="Teacher feedback" />
          <div className="space-y-3">
            {feedback.map((f) => (
              <div key={f.id} className="rounded-2xl border bg-card p-4 shadow-card">
                <div className="mb-1 flex items-center justify-between">
                  <p className="text-sm font-semibold">{f.teacher_name}</p>
                  <span className="text-xs text-muted-foreground">
                    {new Date(f.created_at).toLocaleDateString(undefined, { month: "short", day: "numeric" })}
                  </span>
                </div>
                {f.category && <span className="mb-2 inline-block rounded-full bg-lavender-100 px-2 py-0.5 text-xs text-lavender-800 dark:bg-lavender-500/15 dark:text-lavender-300">{f.category}</span>}
                <p className="text-sm text-muted-foreground">{f.body}</p>
              </div>
            ))}
          </div>
        </section>

        <section>
          <SectionHeader title="Achievements" />
          <div className="space-y-3">
            {achievements.map((a) => (
              <div key={a.id} className="flex items-center gap-4 rounded-2xl border border-border/60 bg-card p-4">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-peach-400/90 to-lavender-500/90 text-white shadow-xs">
                  {a.icon === "Flame" ? <Flame className="h-5 w-5" /> : a.icon === "Clock" ? <Clock className="h-5 w-5" /> : <Trophy className="h-5 w-5" />}
                </div>
                <div>
                  <p className="text-sm font-semibold">{a.title}</p>
                  <p className="text-xs text-muted-foreground">{a.description}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}