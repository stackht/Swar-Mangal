"use client";

import * as React from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import {
  Bell, Music, TrendingUp, Target, Award,
} from "lucide-react";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ProgressRing } from "@/components/dashboard/progress-ring";
import { MusicWave } from "@/components/music/music-wave";
import { listVariants, itemVariants } from "@/lib/motion";
import { classes, practice, progress, assignments } from "@/lib/data/demo";
import { formatTime } from "@/lib/utils/cn";

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

export default function ParentDashboard() {
  const { user } = useAuth();
  const nextClass = classes.find((c) => c.student_ids.includes("s1"));
  const weekMins = practice.reduce((s, p) => s + p.minutes, 0);
  const pct = Math.round((weekMins / 150) * 100);
  const pending = assignments.filter((a) => a.student_id === "s1" && a.status === "pending");

  return (
    <div className="space-y-10">
      {/* HEADER */}
      <motion.header variants={listVariants} initial="hidden" animate="visible" className="flex items-center justify-between gap-4">
        <motion.div variants={itemVariants} className="flex items-center gap-3.5">
          <Avatar name={user?.full_name ?? "Rohan"} src={user?.avatar_url} size="lg" />
          <div>
            <p className="text-eyebrow">Parent</p>
            <h1 className="text-display text-primary">{greeting()}, {user?.full_name?.split(" ")[0] ?? "Rohan"}</h1>
            <p className="text-body-sm text-muted-foreground mt-0.5">Monitoring Aarav{"'"}s musical journey</p>
          </div>
        </motion.div>
        <motion.div variants={itemVariants}>
          <Button variant="ghost" size="icon" asChild className="relative">
            <Link href="/parent/notifications">
              <Bell className="h-5 w-5" />
              <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-violet-500" />
            </Link>
          </Button>
        </motion.div>
      </motion.header>

      {/* CHILD SUMMARY */}
      <motion.div variants={listVariants} initial="hidden" animate="visible">
        <h3 className="text-eyebrow mb-3">Child{"'"}s music journey</h3>
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-violet-100 text-violet-600 dark:bg-violet-500/15 dark:text-violet-300 mb-2"><Music className="h-4 w-4" /></div>
            <p className="text-caption text-muted-foreground">Practice</p>
            <p className="text-xl font-bold tabular-nums mt-0.5">{Math.floor(weekMins / 60)}h {weekMins % 60}m</p>
            <p className="text-xs text-muted-foreground mt-0.5">This week</p>
          </motion.div>
          <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-100 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-300 mb-2"><Target className="h-4 w-4" /></div>
            <p className="text-caption text-muted-foreground">Sessions</p>
            <p className="text-xl font-bold tabular-nums mt-0.5">5</p>
            <p className="text-xs text-muted-foreground mt-0.5">This week</p>
          </motion.div>
          <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-100 text-amber-600 dark:bg-amber-500/15 dark:text-amber-300 mb-2"><TrendingUp className="h-4 w-4" /></div>
            <p className="text-caption text-muted-foreground">Streak</p>
            <p className="text-xl font-bold tabular-nums mt-0.5">3 days</p>
            <p className="text-xs text-muted-foreground mt-0.5">Keep going</p>
          </motion.div>
          <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-rose-100 text-rose-600 dark:bg-rose-500/15 dark:text-rose-300 mb-2"><Award className="h-4 w-4" /></div>
            <p className="text-caption text-muted-foreground">Goal</p>
            <p className="text-xl font-bold tabular-nums mt-0.5">{pct}%</p>
            <p className="text-xs text-muted-foreground mt-0.5">Weekly goal</p>
          </motion.div>
        </div>
      </motion.div>

      {/* PROGRESS RING */}
      <motion.div variants={listVariants} initial="hidden" animate="visible">
        <h3 className="text-eyebrow mb-3">Instrument progress</h3>
        <div className="rounded-2xl border border-border/50 bg-card p-6">
          <div className="flex items-center gap-6">
            <ProgressRing value={progress.overall} size={96} stroke={10} color="hsl(var(--primary))" label={`${progress.overall}`} sublabel="overall" />
            <div className="flex-1">
              <p className="text-h2">{progress.instrument}</p>
              <p className="text-body-sm text-muted-foreground">{progress.level} · {progress.overall}% skill score</p>
              <div className="mt-3 h-12 opacity-50"><MusicWave bars={24} animate={false} /></div>
            </div>
          </div>
        </div>
      </motion.div>

      {/* NEXT CLASS */}
      {nextClass && (
        <section>
          <h3 className="text-eyebrow mb-3">Upcoming class</h3>
          <div className="flex items-center gap-4 rounded-2xl border border-border/50 bg-card p-5">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-violet-500/20 to-fuchsia-500/20 text-violet-600 dark:text-violet-300">
              <Music className="h-5 w-5" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold">{nextClass.title}</p>
              <p className="text-xs text-muted-foreground">{nextClass.teacher_name} · {nextClass.duration_min} min</p>
            </div>
            <div className="text-right">
              <p className="text-sm font-semibold">{formatTime(nextClass.start_time)}</p>
              <p className="text-xs text-muted-foreground">Today</p>
            </div>
          </div>
        </section>
      )}

      {/* ASSIGNMENTS */}
      {pending.length > 0 && (
        <section>
          <h3 className="text-eyebrow mb-3">Pending assignments</h3>
          <div className="space-y-2">
            {pending.map((a) => (
              <div key={a.id} className="flex items-center gap-3 rounded-2xl border border-border/50 bg-card p-4">
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-amber-100 text-amber-600 dark:bg-amber-500/15 dark:text-amber-300">
                  <Target className="h-4 w-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium">{a.title}</p>
                  <p className="text-xs text-muted-foreground">Due {new Date(a.due_date).toLocaleDateString()}</p>
                </div>
                <Badge variant="secondary">Pending</Badge>
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}