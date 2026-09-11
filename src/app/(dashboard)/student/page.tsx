"use client";

import * as React from "react";
import Link from "next/link";
import { motion, useReducedMotion } from "framer-motion";
import {
  ArrowRight, Bell, Calendar, Flame, Music, TrendingUp,
  ListChecks, Library, Trophy, Clock, Target,
} from "lucide-react";
import { toast } from "sonner";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ProgressRing } from "@/components/dashboard/progress-ring";
import { MusicArtwork } from "@/components/music/music-artwork";
import { MusicRail } from "@/components/music/music-rail";
import { MusicWave } from "@/components/music/music-wave";
import { FrequencyBars } from "@/components/music/frequency-bars";
import { TiltCard } from "@/components/3d/tilt-card";

import { classes, assignments, practice, progress as skillProgress, achievements } from "@/lib/data/demo";
import { countdown } from "@/lib/utils/time";
import { cn } from "@/lib/utils/cn";
import { EASE, listVariants, itemVariants } from "@/lib/motion";
import { instrumentIcon } from "@/lib/music-icons";

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

const ACCENTS = ["from-violet-500 to-fuchsia-400", "from-blue-500 to-cyan-400", "from-emerald-500 to-teal-400", "from-amber-500 to-orange-400", "from-rose-500 to-pink-400", "from-indigo-500 to-violet-400"];

export default function StudentDashboard() {
  const { user } = useAuth();
  const reduced = useReducedMotion();
  const nextClass = classes.find((c) => c.student_ids.includes("s1") && c.status === "scheduled");
  const NextIcon = nextClass ? instrumentIcon(nextClass.instrument) : Music;
  const pending = assignments.filter((a) => a.student_id === "s1" && a.status === "pending");
  const weekMins = practice.reduce((s, p) => s + p.minutes, 0);
  const pct = Math.round((weekMins / 150) * 100);
  const myLessons = classes.filter((c) => c.student_ids.includes("s1"));

  return (
    <div className="space-y-10">
      {/* HEADER */}
      <motion.header variants={listVariants} initial="hidden" animate="visible" className="flex items-center justify-between gap-4">
        <motion.div variants={itemVariants} className="flex items-center gap-3.5">
          <Avatar name={user?.full_name ?? "Student"} src={user?.avatar_url} size="lg" />
          <div>
            <p className="text-eyebrow">Student · Piano</p>
            <h1 className="text-display text-primary">{greeting()}, {user?.full_name?.split(" ")[0] ?? "there"}</h1>
          </div>
        </motion.div>
        <motion.div variants={itemVariants} className="flex items-center gap-1">
          <Button variant="ghost" size="icon" aria-label="Schedule" asChild>
            <Link href="/student/schedule"><Calendar className="h-5 w-5" /></Link>
          </Button>
          <Button variant="ghost" size="icon" aria-label="Notifications" asChild className="relative">
            <Link href="/student/notifications">
              <Bell className="h-5 w-5" />
              <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-violet-500" />
            </Link>
          </Button>
        </motion.div>
      </motion.header>

      {/* HERO: Next Session */}
      {nextClass && (
        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, delay: 0.1, ease: EASE }}>
          <TiltCard className="rounded-3xl" maxTilt={4}>
            <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-violet-600 via-purple-500 to-fuchsia-500 p-6 sm:p-8">
              {/* Waveform decoration */}
              <div className="absolute bottom-0 left-0 right-0 h-24 opacity-[0.12]">
                <MusicWave bars={40} className="text-white" animate={false} />
              </div>
              {/* Content */}
              <div className="relative z-10 flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
                <div className="space-y-4">
                  <Badge className="bg-white/15 text-white border-white/20">
                    <Clock className="h-3 w-3" /> Next class · {countdown(nextClass.start_time)}
                  </Badge>
                  <div>
                    <p className="text-xs font-medium text-white/60 uppercase tracking-wider mb-1">Continue your journey</p>
                    <h2 className="text-h1 text-white leading-tight">{nextClass.title}</h2>
                    <p className="text-body-sm text-white/70 mt-1">
                      {nextClass.teacher_name} · {nextClass.duration_min} min · {nextClass.room ?? nextClass.mode}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <Button size="lg" className="bg-white text-violet-700 hover:bg-white/90 shadow-lg" onClick={() => toast.success(`Joining ${nextClass.title}`)}>
                    Join Class <ArrowRight className="h-4 w-4" />
                  </Button>
                  <Button size="lg" variant="ghost" className="text-white border-white/20 hover:bg-white/10" asChild>
                    <Link href="/student/classes">Details</Link>
                  </Button>
                </div>
              </div>
            </div>
          </TiltCard>
        </motion.div>
      )}

      {/* QUICK ACTIONS — compact music actions */}
      <motion.section variants={listVariants} initial="hidden" animate="visible">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          {[
            { icon: <Music className="h-5 w-5" />, label: "Practice", href: "/student/practice", gradient: "from-violet-500 to-purple-400" },
            { icon: <Calendar className="h-5 w-5" />, label: "Lessons", href: "/student/classes", gradient: "from-blue-500 to-cyan-400" },
            { icon: <ListChecks className="h-5 w-5" />, label: "Assignments", href: "/student/assignments", gradient: "from-amber-500 to-orange-400" },
            { icon: <Library className="h-5 w-5" />, label: "Library", href: "/student/library", gradient: "from-emerald-500 to-teal-400" },
          ].map((a) => (
            <motion.button key={a.label} variants={itemVariants} whileHover={{ y: -2 }} whileTap={{ scale: 0.98 }} onClick={() => (window.location.href = a.href)}
              className="flex items-center gap-3 rounded-2xl border border-border/50 bg-card p-4 text-left transition-shadow hover:shadow-soft">
              <span className={cn("flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br text-white", a.gradient)}>
                {a.icon}
              </span>
              <span className="text-sm font-semibold">{a.label}</span>
            </motion.button>
          ))}
        </div>
      </motion.section>

      {/* MUSIC TODAY — compact modules */}
      <section>
        <h3 className="text-eyebrow mb-4">Your music today</h3>
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <MetricModule icon={<Clock className="h-4 w-4" />} label="Practice" value={`${weekMins} min`} sub={`${pct}% of goal`} accent="violet" />
          <MetricModule icon={<Flame className="h-4 w-4" />} label="Streak" value="3 days" sub="Keep going" accent="orange" />
          <MetricModule icon={<Target className="h-4 w-4" />} label="Assignments" value={`${pending.length}`} sub="pending" accent="amber" />
          <MetricModule icon={<TrendingUp className="h-4 w-4" />} label="Progress" value={`${skillProgress.overall}%`} sub="overall skill" accent="emerald" />
        </div>
      </section>

      {/* CONTINUE LEARNING — artwork rail */}
      <section>
        <MusicRail label="Continue learning">
          {myLessons.slice(0, 5).map((l, i) => (
            <div key={l.id} className="snap-start shrink-0 w-48 sm:w-56">
              <MusicArtwork
                gradient={ACCENTS[i % ACCENTS.length]}
                label={l.title}
                sublabel={l.instrument}
                icon={<NextIcon className="h-5 w-5" />}
                aspect="aspect-[4/3]"
                playLabel="Start"
              />
            </div>
          ))}
        </MusicRail>
      </section>

      {/* RECENT PRACTICE */}
      <section>
        <div className="flex items-end justify-between mb-4">
          <h3 className="text-eyebrow">Recent practice</h3>
          <Link href="/student/practice" className="text-xs font-medium text-primary hover:underline">View all</Link>
        </div>
        <div className="space-y-2">
          {practice.slice(0, 4).map((p, i) => (
            <motion.div key={p.id} initial={{ opacity: 0, y: 8 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.04, ease: EASE }}
              className="flex items-center gap-4 rounded-2xl border border-border/50 bg-card p-4">
              <div className="h-8 w-16 opacity-60"><FrequencyBars bars={12} playing={i === 0} /></div>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium">{p.activity}</p>
                <p className="text-xs text-muted-foreground">{p.instrument} · {new Date(p.date).toLocaleDateString(undefined, { month: "short", day: "numeric" })}</p>
              </div>
              <span className="text-sm font-semibold tabular-nums">{p.minutes} min</span>
            </motion.div>
          ))}
        </div>
      </section>

      {/* PROGRESS — skill visualization */}
      <section>
        <div className="flex items-end justify-between mb-4">
          <h3 className="text-eyebrow">Your progress</h3>
          <Link href="/student/progress" className="text-xs font-medium text-primary hover:underline">Details</Link>
        </div>
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          {skillProgress.categories.slice(0, 4).map((c, i) => (
            <motion.div key={c.name} initial={{ opacity: 0, y: 8 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.05, ease: EASE }}
              className="rounded-2xl border border-border/50 bg-card p-4">
              <div className="flex items-center justify-between mb-3">
                <span className="text-caption text-muted-foreground">{c.name}</span>
                <span className="text-sm font-bold tabular-nums text-primary">{c.score}</span>
              </div>
              <ProgressRing value={c.score} size={52} stroke={5} color="hsl(var(--primary))" label={`${c.score}`} />
            </motion.div>
          ))}
        </div>
      </section>

      {/* ACHIEVEMENTS — elegant milestones */}
      <section>
        <h3 className="text-eyebrow mb-4">Achievements</h3>
        <div className="space-y-2">
          {achievements.slice(0, 3).map((a) => (
            <div key={a.title} className="flex items-center gap-4 rounded-2xl border border-border/50 bg-card p-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-violet-500/20 to-fuchsia-500/20 text-violet-600 dark:text-violet-300">
                {a.icon === "F" ? <Flame className="h-5 w-5" /> : a.icon === "C" ? <Clock className="h-5 w-5" /> : <Trophy className="h-5 w-5" />}
              </div>
              <div>
                <p className="text-sm font-medium">{a.title}</p>
                <p className="text-xs text-muted-foreground">{a.description}</p>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

function MetricModule({ icon, label, value, sub, accent }: {
  icon: React.ReactNode; label: string; value: string; sub: string; accent: string;
}) {
  const accentColor = cn(
    accent === "violet" && "bg-violet-100 text-violet-600 dark:bg-violet-500/15 dark:text-violet-300",
    accent === "orange" && "bg-orange-100 text-orange-600 dark:bg-orange-500/15 dark:text-orange-300",
    accent === "amber" && "bg-amber-100 text-amber-600 dark:bg-amber-500/15 dark:text-amber-300",
    accent === "emerald" && "bg-emerald-100 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-300",
  );
  return (
    <div className="rounded-2xl border border-border/50 bg-card p-4">
      <div className={cn("flex h-8 w-8 items-center justify-center rounded-lg mb-3", accentColor)}>{icon}</div>
      <p className="text-caption text-muted-foreground">{label}</p>
      <p className="text-xl font-bold tabular-nums mt-0.5">{value}</p>
      <p className="text-xs text-muted-foreground mt-0.5">{sub}</p>
    </div>
  );
}
