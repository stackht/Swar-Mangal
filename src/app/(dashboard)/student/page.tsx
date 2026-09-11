"use client";

import * as React from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import {
  ArrowRight,
  Bell,
  CalendarDays,
  CheckCircle2,
  ClipboardList,
  Clock,
  Flame,
  Library,
  Mic2,
  Music,
  Sparkles,
  Video,
  Play,
} from "lucide-react";
import { toast } from "sonner";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { GradientCard } from "@/components/dashboard/gradient-card";
import { TiltCard, MagneticButton } from "@/components/3d/tilt-card";
import { SectionHeader } from "@/components/dashboard/section-header";
import { ProgressRing } from "@/components/dashboard/progress-ring";
import { MusicWave } from "@/components/music/music-wave";

import { classes, assignments, activity, progress as skillProgress, achievements } from "@/lib/data/demo";
import { formatTime } from "@/lib/utils/cn";
import { countdown } from "@/lib/utils/time";
import { instrumentIcon } from "@/lib/music-icons";
import { EASE, listVariants, itemVariants, useMotionPrefs } from "@/lib/motion";
import { cn } from "@/lib/utils/cn";

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

function greetingSub() {
  const h = new Date().getHours();
  if (h < 12) return "A fresh day — ready to make music?";
  if (h < 17) return "Ready for your next session?";
  return "Time to unwind with some practice.";
}

const quickActions: {
  title: string;
  caption: string;
  href: string;
  icon: typeof Play;
  accent: "lavender" | "mint" | "peach" | "sky";
}[] = [
  { title: "Practice", caption: "Start a session", href: "/student/practice", icon: Play, accent: "lavender" },
  { title: "Classes", caption: "Your schedule", href: "/student/classes", icon: CalendarDays, accent: "sky" },
  { title: "Assignments", caption: "2 due this week", href: "/student/assignments", icon: ClipboardList, accent: "peach" },
  { title: "Library", caption: "Sheets & audio", href: "/student/library", icon: Library, accent: "mint" },
];

const accentChip: Record<string, string> = {
  lavender: "bg-lavender-100/80 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300",
  mint: "bg-mint-100/80 text-mint-700 dark:bg-mint-500/15 dark:text-mint-300",
  peach: "bg-peach-100/80 text-peach-700 dark:bg-peach-500/15 dark:text-peach-300",
  sky: "bg-sky-100/80 text-sky-700 dark:bg-sky-500/15 dark:text-sky-300",
};

const activityIcon: Record<string, typeof Music> = {
  lesson: Mic2,
  assignment: ClipboardList,
  practice: Music,
  feedback: Sparkles,
};

export default function StudentDashboard() {
  const { user } = useAuth();
  const { reduced } = useMotionPrefs();
  const nextClass = classes.find((c) => c.student_ids.includes("s1") && c.status === "scheduled");
  const myClasses = classes.filter((c) => c.student_ids.includes("s1"));
  const myAssignments = assignments.filter((a) => a.student_id === "s1");
  const dueAssignments = myAssignments.filter((a) => a.status === "pending");
  const NextIcon = nextClass ? instrumentIcon(nextClass.instrument) : Music;

  return (
    <div className="space-y-10">
      <motion.header
        variants={listVariants}
        initial="hidden"
        animate="visible"
        className="flex flex-wrap items-center justify-between gap-4"
      >
        <motion.div variants={itemVariants} className="flex items-center gap-3.5">
          <Avatar name={user?.full_name ?? "Student"} src={user?.avatar_url} size="lg" className="ring-1 ring-border/60" />
          <div>
            <p className="text-eyebrow">Student · Piano</p>
            <h1 className="text-display text-balance">
              {greeting()}, {user?.full_name?.split(" ")[0] ?? "there"}.
            </h1>
            <p className="mt-0.5 text-body-sm text-muted-foreground">{greetingSub()}</p>
          </div>
        </motion.div>
        <motion.div variants={itemVariants} className="flex items-center gap-1">
          <Button variant="ghost" size="icon" aria-label="Calendar" asChild>
            <Link href="/student/schedule"><CalendarDays className="h-[18px] w-[18px]" /></Link>
          </Button>
          <Button variant="ghost" size="icon" aria-label="Notifications" asChild className="relative">
            <Link href="/student/notifications">
              <Bell className="h-[18px] w-[18px]" />
              <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-peach-500 ring-2 ring-background" />
            </Link>
          </Button>
        </motion.div>
      </motion.header>

      {/* NEXT CLASS */}
      {nextClass && (
        <motion.section
          initial={{ opacity: 0, y: reduced ? 0 : 14 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.08, ease: EASE }}
        >
          <TiltCard className="rounded-3xl" maxTilt={4}>
        <GradientCard gradient="navy" className="p-6 sm:p-8" wave>
          <div className="relative z-10 flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
            <div className="space-y-3">
              <Badge className="bg-white/10 text-white/90 ring-1 ring-white/15">
                <Clock className="h-3 w-3" /> Next class · in {countdown(nextClass.start_time)}
              </Badge>
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/10 text-white ring-1 ring-white/15">
                  <NextIcon className="h-5 w-5" />
                </span>
                <div>
                  <h2 className="text-h1 text-white">{nextClass.title}</h2>
                  <p className="text-body-sm text-white/70">
                    Today · {formatTime(nextClass.start_time)} · {nextClass.duration_min} min
                  </p>
                </div>
              </div>
              <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-white/75">
                <span className="flex items-center gap-1.5"><Sparkles className="h-3.5 w-3.5" /> with {nextClass.teacher_name}</span>
                <span className="hidden text-white/25 sm:inline">·</span>
                <span className="flex items-center gap-1.5 capitalize">
                  {nextClass.mode === "online" ? <Video className="h-3.5 w-3.5" /> : <Music className="h-3.5 w-3.5" />} {nextClass.room ?? nextClass.mode}
                </span>
              </div>
            </div>
            <div className="lg:text-right">
              <MagneticButton strength={8}>
                <Button
                  size="lg"
                  className="bg-white text-navy-950 shadow-lift hover:bg-white/92"
                  onClick={() => toast.success(`Joining ${nextClass.title}`)}
                >
                  Join class <ArrowRight className="h-4 w-4" />
                </Button>
              </MagneticButton>
            </div>
          </div>
        </GradientCard>
      </TiltCard>
        </motion.section>
      )}

      {/* QUICK ACTIONS */}
      <motion.section
        variants={listVariants}
        initial="hidden"
        animate="visible"
        className="grid grid-cols-2 gap-3 lg:grid-cols-4"
      >
        {quickActions.map((a) => (
          <motion.button
            key={a.title}
            variants={itemVariants}
            whileHover={reduced ? undefined : { y: -2 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => (window.location.href = a.href)}
            className="flex flex-col items-start gap-4 rounded-2xl border border-border/60 bg-card p-4 text-left transition-[box-shadow,transform] duration-200 ease-ease-out-expo hover:shadow-soft"
            aria-label={a.title}
          >
            <span className={cn("flex h-9 w-9 items-center justify-center rounded-xl", accentChip[a.accent])}>
              <a.icon className="h-4 w-4" />
            </span>
            <span>
              <span className="block text-sm font-semibold">{a.title}</span>
              <span className="block text-xs text-muted-foreground">{a.caption}</span>
            </span>
          </motion.button>
        ))}
      </motion.section>

      {/* TODAY */}
      <motion.section variants={listVariants} initial="hidden" animate="visible">
        <SectionHeader title="Today" />
        <div className="surface divide-y divide-border/60">
          {dueAssignments.slice(0, 1).map((a) => (
            <Link key={a.id} href="/student/assignments" className="group flex items-center gap-4 p-4 transition-colors hover:bg-secondary/60">
              <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-peach-100/80 text-peach-700 dark:bg-peach-500/15 dark:text-peach-300">
                <ClipboardList className="h-4 w-4" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{a.title}</p>
                <p className="text-xs text-muted-foreground">Assignment due in {countdown(a.due_date)}</p>
              </div>
              <ArrowRight className="h-4 w-4 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-0.5" />
            </Link>
          ))}
          {myClasses.slice(0, 1).map((c) => {
            const Icon = instrumentIcon(c.instrument);
            return (
              <Link key={c.id} href="/student/classes" className="group flex items-center gap-4 p-4 transition-colors hover:bg-secondary/60">
                <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-lavender-100/80 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300">
                  <Icon className="h-4 w-4" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">{c.title}</p>
                  <p className="text-xs text-muted-foreground">{formatTime(c.start_time)} · with {c.teacher_name}</p>
                </div>
                <ArrowRight className="h-4 w-4 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-0.5" />
              </Link>
            );
          })}
        </div>
      </motion.section>

      {/* PRACTICE + PROGRESS */}
      <motion.section variants={listVariants} initial="hidden" animate="visible" className="grid gap-6 lg:grid-cols-2">
        <div className="surface p-5 lg:h-fit lg:sticky lg:top-24">
          <div className="mb-4 flex items-start justify-between">
            <div>
              <p className="text-eyebrow">Practice</p>
              <p className="text-h2 mt-0.5">This week</p>
            </div>
            <Link href="/student/practice" className="text-sm font-medium text-primary hover:underline">View</Link>
          </div>
          <div className="flex items-center gap-4">
            <ProgressRing value={62} size={84} color="hsl(253 72% 60%)" label="62%" sublabel="of 150 min" />
            <div className="min-w-0 flex-1">
              <p className="text-sm font-semibold">93 min logged</p>
              <p className="text-xs text-muted-foreground">57 min to reach your weekly goal</p>
              <div className="mt-3 space-y-1.5">
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <Flame className="h-3.5 w-3.5 text-peach-500" /> 3-day streak
                </div>
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <CheckCircle2 className="h-3.5 w-3.5 text-mint-500" /> 2 sessions completed
                </div>
              </div>
            </div>
          </div>
          <div className="mt-5 h-12 rounded-xl bg-secondary/60">
            <MusicWave bars={30} animate height={48} className="opacity-40" ariaHidden />
          </div>
        </div>

        <div className="surface p-5">
          <div className="mb-4 flex items-start justify-between">
            <div>
              <p className="text-eyebrow">Progress</p>
              <p className="text-h2 mt-0.5">{skillProgress.instrument} · {skillProgress.level}</p>
            </div>
            <Link href="/student/progress" className="text-sm font-medium text-primary hover:underline">View</Link>
          </div>
          <div className="space-y-3.5">
            {skillProgress.categories.slice(0, 5).map((cat) => (
              <div key={cat.name}>
                <div className="mb-1.5 flex items-center justify-between text-[13px]">
                  <span className="text-muted-foreground">{cat.name}</span>
                  <span className="tabular-nums font-medium">{cat.score}</span>
                </div>
                <div className="h-1.5 overflow-hidden rounded-full bg-secondary">
                  <motion.div
                    className="h-full rounded-full bg-gradient-to-r from-lavender-500 to-mint-500"
                    initial={{ width: 0 }}
                    whileInView={{ width: `${cat.score}%` }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.8, ease: EASE, delay: 0.1 }}
                  />
                </div>
              </div>
            ))}
          </div>
          <div className="mt-4 border-t border-border/60 pt-3 text-xs text-muted-foreground">
            Overall skill <span className="font-semibold text-foreground">{skillProgress.overall}%</span> · up 4% this month
          </div>
        </div>
      </motion.section>

      {/* ACTIVITY + ACHIEVEMENTS */}
      <motion.section variants={listVariants} initial="hidden" animate="visible" className="grid gap-6 lg:grid-cols-2">
        <div>
          <SectionHeader title="Recent activity" />
          <div className="surface divide-y divide-border/60">
            {activity.slice(0, 4).map((a) => {
              const Icon = activityIcon[a.type] ?? Music;
              return (
                <div key={a.id} className="flex items-center gap-4 p-4">
                  <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-secondary text-muted-foreground">
                    <Icon className="h-4 w-4" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium">{a.title}</p>
                    <p className="truncate text-xs text-muted-foreground">{a.detail}</p>
                  </div>
                  <span className="shrink-0 text-xs tabular-nums text-muted-foreground">
                    {new Date(a.created_at).toLocaleDateString(undefined, { month: "short", day: "numeric" })}
                  </span>
                </div>
              );
            })}
          </div>
        </div>

        <div>
          <SectionHeader title="Achievements" />
          <div className="space-y-2">
            {achievements.slice(0, 3).map((ach) => (
              <div key={ach.id} className="flex items-center gap-4 rounded-2xl border border-border/60 bg-card p-4">
                <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-peach-400/90 to-lavender-500/90 text-white shadow-xs">
                  {ach.icon === "Flame" ? <Flame className="h-5 w-5" /> : ach.icon === "Clock" ? <Clock className="h-5 w-5" /> : <Sparkles className="h-5 w-5" />}
                </span>
                <div className="min-w-0">
                  <p className="text-sm font-semibold">{ach.title}</p>
                  <p className="truncate text-xs text-muted-foreground">{ach.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </motion.section>
    </div>
  );
}