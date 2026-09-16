"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion, useReducedMotion } from "framer-motion";
import {
  ArrowRight, Bell, Calendar, Clock, Flame, ListChecks, Library,
  Music, Search, Sparkles, Target, TrendingUp, Trophy,
} from "lucide-react";
import { toast } from "sonner";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ProgressRing } from "@/components/dashboard/progress-ring";
import { MusicArtwork } from "@/components/music/music-artwork";
import { MusicWave } from "@/components/music/music-wave";
import { FrequencyBars } from "@/components/music/frequency-bars";
import { AmbientGlow } from "@/components/music/ambient-glow";
import { TiltCard, MagneticButton } from "@/components/3d/tilt-card";
import { useCommandPalette } from "@/components/command/command-palette";

import { useAcademyData } from "@/hooks/use-academy-data";
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

function greetingSub() {
  const h = new Date().getHours();
  if (h < 12) return "A fresh day · ready to make music?";
  if (h < 17) return "Your next session is in reach.";
  return "Wind down with some practice.";
}

const ACCENTS = [
  "from-violet-500 to-fuchsia-500",
  "from-blue-500 to-cyan-400",
  "from-emerald-500 to-teal-400",
  "from-amber-500 to-orange-400",
  "from-rose-500 to-pink-400",
  "from-indigo-500 to-violet-500",
];

/** Filter pills · map to real student routes. */
const PILLS: { label: string; href: string }[] = [
  { label: "All", href: "/student" },
  { label: "Practice", href: "/student/practice" },
  { label: "Lessons", href: "/student/classes" },
  { label: "Assignments", href: "/student/assignments" },
  { label: "Library", href: "/student/library" },
  { label: "Progress", href: "/student/progress" },
];

export default function StudentDashboard() {
const { classes, assignments, practice, progress: skillProgress, achievements , currentStudentId } = useAcademyData();
  const { user } = useAuth();
  const pathname = usePathname();
  const reduced = useReducedMotion();
  const { open: openCmd } = useCommandPalette();
  const nextClass = classes.find((c) => c.student_ids.includes(currentStudentId) && c.status === "scheduled");
  const NextIcon = nextClass ? instrumentIcon(nextClass.instrument) : Music;
  const pending = assignments.filter((a) => a.student_id === currentStudentId && a.status === "pending");
  const weekMins = practice.reduce((s, p) => s + p.minutes, 0);
  const pct = Math.min(100, Math.round((weekMins / 150) * 100));
  const myLessons = classes.filter((c) => c.student_ids.includes(currentStudentId));
  const todayMins = practice.find((p) => new Date(p.date).toDateString() === new Date().toDateString())?.minutes ?? 0;

  return (
    <div className="relative pb-10">
      {/* Ambient cinematic glow behind header + hero */}
      <AmbientGlow className="z-0" />

      <div className="relative z-10 space-y-12">
        {/* ============ HEADER ============ */}
        <motion.header variants={listVariants} initial="hidden" animate="visible" className="flex items-center justify-between gap-4">
          <motion.div variants={itemVariants} className="flex items-center gap-3.5">
            <div className="relative">
              <Avatar name={user?.full_name ?? "Student"} src={user?.avatar_url} size="lg" className="ring-2 ring-primary/20 ring-offset-2 ring-offset-background" />
              <span className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full bg-lime-400 ring-2 ring-background" aria-hidden />
            </div>
            <div>
              <p className="text-eyebrow">Piano ·· Grade 3</p>
              <h1 className="text-[22px] font-bold leading-tight tracking-tight sm:text-[26px]">{greeting()}<span className="text-primary">, {user?.full_name?.split(" ")[0] ?? "there"}</span></h1>
              <p className="mt-0.5 text-body-sm text-muted-foreground">{greetingSub()}</p>
            </div>
          </motion.div>
          <motion.div variants={itemVariants} className="flex items-center gap-1.5">
            <button
              onClick={() => openCmd(true)}
              aria-label="Search"
              className="hidden h-10 w-10 items-center justify-center rounded-full border border-border/50 bg-card text-muted-foreground transition-all hover:border-primary/30 hover:text-primary hover:shadow-soft sm:flex"
            >
              <Search className="h-[18px] w-[18px]" />
            </button>
            <Button variant="ghost" size="icon" asChild className="hidden sm:inline-flex">
              <Link href="/student/schedule"><Calendar className="h-5 w-5" /></Link>
            </Button>
            <Button variant="ghost" size="icon" asChild className="relative">
              <Link href="/student/notifications">
                <Bell className="h-5 w-5" />
                <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-lime-500 ring-2 ring-background" />
              </Link>
            </Button>
          </motion.div>
        </motion.header>

        {/* ============ HERO · NEXT SESSION ============ */}
        {nextClass && (
          <motion.div initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.55, delay: 0.08, ease: EASE }}>
            <TiltCard className="rounded-[1.75rem] sm:rounded-[2rem]" maxTilt={4}>
              <div className="relative overflow-hidden rounded-[1.75rem] sm:rounded-[2rem] p-6 sm:p-8">
                {/* Cinematic layered background */}
                <div className="absolute inset-0 bg-gradient-to-br from-[#1B1440] via-[#251A54] to-[#3B1A63]" />
                <div className="absolute -right-16 -top-24 h-72 w-72 rounded-full bg-violet-500/20 blur-3xl" />
                <div className="absolute -left-10 bottom-0 h-56 w-56 rounded-full bg-fuchsia-500/10 blur-3xl" />

                {/* Waveform signature */}
                <div className="absolute inset-x-0 bottom-0 z-0 h-20 opacity-[0.14]">
                  <MusicWave bars={48} height={80} animate={reduced ? false : true} className="text-white" />
                </div>

                {/* Content */}
                <div className="relative z-10">
                  <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
                    {/* Artwork + copy */}
                    <div className="flex flex-col gap-5 sm:flex-row sm:items-center lg:max-w-xl">
                      <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-[1.4rem] bg-gradient-to-br from-violet-500/90 to-fuchsia-500/90 shadow-glow transition-transform duration-300 group-hover:scale-105 sm:h-24 sm:w-24">
                        <NextIcon className="h-10 w-10 text-white" strokeWidth={1.6} />
                      </div>
                      <div className="space-y-3">
                        <Badge className="w-fit border-white/15 bg-white/10 text-white/90 backdrop-blur-sm">
                          <span className="relative flex h-1.5 w-1.5">
                            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-lime-400 opacity-75" />
                            <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-lime-400" />
                          </span>
                          Next class ·· {countdown(nextClass.start_time)}
                        </Badge>
                        <div>
                          <p className="text-[11px] text-white/55 uppercase tracking-[0.18em]">Continue your journey</p>
                          <h2 className="mt-1 text-h1 text-white leading-tight">{nextClass.title}</h2>
                          <p className="mt-1.5 flex flex-wrap items-center gap-x-2 gap-y-0.5 text-sm text-white/70">
                            <span className="flex items-center gap-1.5"><Sparkles className="h-3.5 w-3.5" /> {nextClass.teacher_name}</span>
                            <span className="hidden text-white/30 sm:inline">··</span>
                            <span>Today ·· {new Date(nextClass.start_time).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}</span>
                            <span className="text-white/30">··</span>
                            <span>{nextClass.duration_min} min</span>
                            <span className="hidden text-white/30 sm:inline">··</span>
                            <span className="capitalize">{nextClass.room ?? nextClass.mode}</span>
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* CTA */}
                    <div className="flex items-center gap-3 lg:flex-col lg:items-stretch">
                      <MagneticButton strength={10}>
                        <Button size="lg" className="w-full rounded-full bg-white px-7 text-violet-700 shadow-lift hover:bg-white/95" onClick={() => toast.success(`Joining ${nextClass.title}`)}>
                          <span className="mr-1 flex h-6 w-6 items-center justify-center rounded-full bg-violet-600 text-white">
                            <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z" /></svg>
                          </span>
                          Join Class <ArrowRight className="h-4 w-4" />
                        </Button>
                      </MagneticButton>
                      <Button size="lg" variant="ghost" className="rounded-full text-white hover:bg-white/10 hover:text-white" asChild>
                        <Link href="/student/classes">View details</Link>
                      </Button>
                    </div>
                  </div>
                </div>
              </div>
            </TiltCard>
          </motion.div>
        )}

        {/* ============ CATEGORY PILLS ============ */}
        <motion.div variants={listVariants} initial="hidden" animate="visible" className="-mx-4">
          <div className="flex gap-2 overflow-x-auto px-4 pb-1 no-scrollbar sm:mx-0 sm:px-0 sm:flex-wrap">
            {PILLS.map((p) => {
              const active = pathname === p.href || (p.href !== "/student" && pathname.startsWith(p.href));
              return (
                <Link key={p.label} href={p.href} className={cn("shrink-0 rounded-full border px-4 py-2 text-[13px] font-medium transition-all",
                  active ? "border-transparent bg-primary text-primary-foreground shadow-glow"
                         : "border-border/60 bg-card text-muted-foreground hover:border-primary/30 hover:text-primary")}>
                  {p.label}
                </Link>
              );
            })}
          </div>
        </motion.div>

        {/* ============ QUICK ACTIONS ============ */}
        <motion.section variants={listVariants} initial="hidden" animate="visible">
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              { icon: <Music className="h-5 w-5" />, label: "Practice", sub: "Start a session", href: "/student/practice", accent: "from-violet-500 to-purple-500" },
              { icon: <Calendar className="h-5 w-5" />, label: "Lessons", sub: "My schedule", href: "/student/classes", accent: "from-blue-500 to-cyan-500" },
              { icon: <ListChecks className="h-5 w-5" />, label: "Assignments", sub: `${pending.length} due`, href: "/student/assignments", accent: "from-amber-500 to-orange-400" },
              { icon: <Library className="h-5 w-5" />, label: "Library", sub: "Sheets & audio", href: "/student/library", accent: "from-emerald-500 to-teal-500" },
            ].map((a) => (
              <motion.button key={a.label} variants={itemVariants} whileHover={{ y: -2 }} whileTap={{ scale: 0.98 }}
                onClick={() => (window.location.href = a.href)}
                className="group flex items-center gap-3.5 rounded-2xl border border-border/50 bg-card/70 p-4 text-left backdrop-blur-sm transition-all hover:border-transparent hover:shadow-lift">
                <span className={cn("flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br text-white shadow-soft transition-transform duration-300 group-hover:scale-105", a.accent)}>
                  {a.icon}
                </span>
                <span className="min-w-0">
                  <span className="block text-sm font-semibold leading-none">{a.label}</span>
                  <span className="mt-1 block text-xs text-muted-foreground">{a.sub}</span>
                </span>
              </motion.button>
            ))}
          </div>
        </motion.section>

        {/* ============ YOUR MUSIC TODAY · cohesive band ============ */}
        <section>
          <SectionHeading title="Here's your music today" action={<Target className="h-4 w-4 text-muted-foreground" />} />
          <div className="surface overflow-hidden rounded-[1.4rem]">
            <div className="grid grid-cols-2 lg:grid-cols-4">
              <TodayMetric icon={<Clock className="h-4 w-4" />} label="Practice today" value={`${todayMins} min`} accentClass="bg-violet-100/70 text-violet-600 dark:bg-violet-500/15 dark:text-violet-300" border="lg:border-r" />
              <TodayMetric icon={<Flame className="h-4 w-4" />} label="Streak" value="3 days" accentClass="bg-orange-100/70 text-orange-600 dark:bg-orange-500/15 dark:text-orange-300" border="lg:border-r" />
              <TodayMetric icon={<Target className="h-4 w-4" />} label="Assignments" value={`${pending.length}`} sub="pending" accentClass="bg-amber-100/70 text-amber-600 dark:bg-amber-500/15 dark:text-amber-300" border="lg:border-r" hideBorder />
              <TodayMetric icon={<TrendingUp className="h-4 w-4" />} label="Progress" value={`${skillProgress.overall}%`} sub="overall skill" accentClass="bg-emerald-100/70 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-300" />
            </div>
            <div className="border-t border-border/50 px-5 py-2.5">
              <FrequencyBars bars={64} playing className="h-4 opacity-30 text-violet-500 dark:text-violet-400" />
            </div>
          </div>
        </section>

        {/* ============ CONTINUE LEARNING RAIL ============ */}
        <section>
          <div className="flex items-end justify-between">
            <h3 className="mb-3 text-base font-semibold tracking-tight">Continue learning</h3>
            <Link href="/student/classes" className="mb-3 text-xs font-medium text-primary hover:underline">See all</Link>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-1 no-scrollbar sm:gap-4">
            {myLessons.slice(0, 5).map((l, i) => (
              <Link key={l.id} href="/student/classes" className="snap-start shrink-0 w-40 sm:w-48">
                <MusicArtwork
                  gradient={ACCENTS[i % ACCENTS.length]}
                  label={l.title}
                  sublabel={l.instrument}
                  icon={<NextIcon className="h-5 w-5" />}
                  aspect="aspect-square"
                  playLabel=" „"
                />
              </Link>
            ))}
          </div>
        </section>

        {/* ============ PRACTICE SUMMARY ============ */}
        <section>
          <SectionHeading title="Your practice rhythm" action={<Link href="/student/practice" className="text-xs font-medium text-primary hover:underline">Open practice</Link>} />
          <div className="relative overflow-hidden rounded-[1.4rem] border border-border/50 bg-card p-5 sm:p-6">
            {/* Waveform as signature */}
            <div className="absolute inset-y-0 left-0 w-1/2 opacity-20 transition-opacity" aria-hidden>
              <MusicWave bars={36} height={200} animate className="text-violet-500 dark:text-violet-400" />
            </div>
            <div className="relative flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-5">
                <ProgressRing value={pct} size={88} stroke={8} color="hsl(var(--primary))" label={`${pct}%`} sublabel="goal" />
                <div className="space-y-1">
                  <p className="text-2xl font-bold leading-none tabular-nums tracking-tight">{weekMins} min</p>
                  <p className="text-body-sm text-muted-foreground">practiced this week</p>
                  <div className="mt-1 flex items-center gap-2 text-xs text-muted-foreground">
                    <Flame className="h-3.5 w-3.5 text-orange-400" />
                    <span>3-day streak</span>
                    <span className="text-muted-foreground/50">··</span>
                    <span>{practice.length} sessions</span>
                  </div>
                </div>
              </div>
              <Button size="lg" className="w-fit rounded-full bg-gradient-to-br from-violet-600 to-fuchsia-600 text-white shadow-lift hover:from-violet-500 hover:to-fuchsia-500" asChild>
                <Link href="/student/practice">
                  <span className="mr-1 flex h-6 w-6 items-center justify-center rounded-full bg-white/20">
                    <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z" /></svg>
                  </span>
                  Start Practice
                </Link>
              </Button>
            </div>
          </div>
        </section>

        {/* ============ PROGRESS ============ */}
        <section>
          <SectionHeading title="Your progress" action={<Link href="/student/progress" className="text-xs font-medium text-primary hover:underline">Details</Link>} />
          <div className="rounded-[1.4rem] border border-border/50 bg-card p-5 sm:p-6">
            <div className="mb-4 flex items-center justify-between">
              <div>
                <p className="text-h3">{skillProgress.instrument}</p>
                <p className="text-body-sm text-muted-foreground">{skillProgress.level} ·· improving steadily</p>
              </div>
              <span className="text-2xl font-bold tabular-nums text-primary">{skillProgress.overall}%</span>
            </div>
            <div className="grid gap-x-6 gap-y-3 sm:grid-cols-2">
              {skillProgress.categories.slice(0, 6).map((c) => (
                <div key={c.name} className="flex items-center gap-3">
                  <span className="w-32 shrink-0 text-caption text-muted-foreground">{c.name}</span>
                  <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-secondary">
                    <motion.div
                      className="h-full rounded-full bg-gradient-to-r from-violet-500 to-fuchsia-500"
                      initial={{ width: 0 }}
                      whileInView={{ width: `${c.score}%` }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.8, ease: EASE, delay: 0.1 }}
                    />
                  </div>
                  <span className="w-8 text-right text-caption tabular-nums text-muted-foreground">{c.score}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ============ RECENT PRACTICE / ACTIVITY ============ */}
        <section>
          <SectionHeading title="Recent practice" action={<Link href="/student/practice" className="text-xs font-medium text-primary hover:underline">View all</Link>} />
          <div className="space-y-2">
            {practice.slice(0, 4).map((p, i) => (
              <motion.div key={p.id} initial={{ opacity: 0, y: 8 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.04, ease: EASE }}
                className="group flex items-center gap-4 rounded-2xl border border-border/40 bg-card/60 p-4 transition-colors hover:bg-card">
                <div className="h-8 w-16 shrink-0 overflow-hidden opacity-60">
                  <FrequencyBars bars={14} playing={i === 0} className="text-violet-500 dark:text-violet-400" />
                </div>
                <div className="h-6 w-px shrink-0 bg-border/60" />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">{p.activity}</p>
                  <p className="text-xs text-muted-foreground">{p.instrument} ·· {new Date(p.date).toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" })}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold tabular-nums">{p.minutes}</p>
                  <p className="text-[10px] uppercase tracking-wider text-muted-foreground">min</p>
                </div>
              </motion.div>
            ))}
          </div>
        </section>

        {/* ============ ACHIEVEMENTS ============ */}
        <section>
          <SectionHeading title="Milestones" action={<Trophy className="h-4 w-4 text-muted-foreground" />} />
          <div className="grid gap-3 sm:grid-cols-3">
            {achievements.slice(0, 3).map((a, i) => (
              <motion.div key={a.title} initial={{ opacity: 0, y: 8 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.05, ease: EASE }}
                className="group relative overflow-hidden rounded-2xl border border-border/50 bg-card p-5 transition-all hover:border-primary/20 hover:shadow-soft">
                <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-violet-500/50 to-transparent opacity-0 transition-opacity group-hover:opacity-100" />
                <div className="flex items-center justify-between">
                  <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-violet-500/15 to-fuchsia-500/15 text-violet-600 dark:text-violet-300">
                    {a.icon === "F" ? <Flame className="h-5 w-5" /> : a.icon === "C" ? <Clock className="h-5 w-5" /> : <Sparkles className="h-5 w-5" />}
                  </span>
                  <span className="text-[10px] font-semibold uppercase tracking-[0.16em] text-muted-foreground">{i === 0 ? "Active" : "Earned"}</span>
                </div>
                <p className="mt-4 text-h3 leading-snug">{a.title}</p>
                <p className="mt-1 text-body-sm text-muted-foreground">{a.description}</p>
              </motion.div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}

/* ---------- Local helpers ---------- */

function SectionHeading({ title, action }: { title: string; action?: React.ReactNode }) {
  return (
    <div className="mb-4 flex items-center justify-between">
      <h3 className="text-[15px] font-semibold tracking-tight">{title}</h3>
      {action}
    </div>
  );
}

function TodayMetric({ icon, label, value, sub, accentClass, border, hideBorder }: {
  icon: React.ReactNode; label: string; value: string; sub?: string; accentClass: string; border?: string; hideBorder?: boolean;
}) {
  return (
    <div className={cn("flex items-center gap-3 p-4 sm:p-5", border, !hideBorder && "border-b border-border/50 lg:border-b-0")}>
      <span className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-xl", accentClass)}>{icon}</span>
      <div className="min-w-0">
        <p className="text-caption text-muted-foreground">{label}</p>
        <div className="flex items-baseline gap-1.5">
          <span className="text-xl font-bold tabular-nums leading-none tracking-tight">{value}</span>
          {sub && <span className="truncate text-xs text-muted-foreground">{sub}</span>}
        </div>
      </div>
    </div>
  );
}