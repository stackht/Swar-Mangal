"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowRight, Bell, ClipboardList, FileUp, Music, UserCheck, Users } from "lucide-react";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { SectionHeader } from "@/components/dashboard/section-header";
import { StatCard } from "@/components/dashboard/stat-card";

import { classes, students, practice, assignments } from "@/lib/data/demo";
import { cn, formatTime } from "@/lib/utils/cn";
import { EASE } from "@/lib/motion";

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

const accentChip: Record<string, string> = {
  lavender: "bg-lavender-100/80 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300",
  mint: "bg-mint-100/80 text-mint-700 dark:bg-mint-500/15 dark:text-mint-300",
  peach: "bg-peach-100/80 text-peach-700 dark:bg-peach-500/15 dark:text-peach-300",
  sky: "bg-sky-100/80 text-sky-700 dark:bg-sky-500/15 dark:text-sky-300",
};

const quickActions = [
  { title: "Mark Attendance", href: "/teacher/attendance", icon: UserCheck, accent: "lavender" },
  { title: "Add Assignment", href: "/teacher/assignments", icon: ClipboardList, accent: "mint" },
  { title: "Give Feedback", href: "/teacher/students", icon: Users, accent: "peach" },
  { title: "Upload Material", href: "/teacher/library", icon: FileUp, accent: "sky" },
];

export default function TeacherDashboard() {
  const { user } = useAuth();
  const todayClasses = classes
    .filter((c) => c.teacher_id === "t1" && new Date(c.start_time).toDateString() === new Date().toDateString())
    .sort((a, b) => +new Date(a.start_time) - +new Date(b.start_time));
  const myStudents = students.filter((s) => classes.some((c) => c.teacher_id === "t1" && c.student_ids.includes(s.id)));
  const lowPractice = myStudents.filter((s) => practice.filter((p) => p.student_id === s.id && new Date(p.date) >= new Date(Date.now() - 7 * 864e5)).reduce((x, p) => x + p.minutes, 0) < 30);
  const toReview = assignments.filter((a) => a.teacher_id === "t1" && a.status === "submitted");

  return (
    <div className="space-y-8">
      <header className="flex flex-wrap items-start justify-between gap-4">
        <div className="flex items-center gap-3">
          <Avatar name={user?.full_name ?? "Sarah Mitchell"} src={user?.avatar_url} size="lg" />
          <div>
            <p className="text-xs font-medium text-muted-foreground">Teacher · Piano</p>
            <h1 className="text-2xl font-bold tracking-tight">{greeting()}, {user?.full_name?.split(" ")[0] ?? "Sarah"}</h1>
            <p className="text-sm text-muted-foreground">You have {todayClasses.length} class{todayClasses.length === 1 ? "" : "es"} today.</p>
          </div>
        </div>
        <Button variant="ghost" size="icon" asChild className="relative">
          <Link href="/teacher/notifications">
            <Bell className="h-5 w-5" />
            <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-peach-500" />
          </Link>
        </Button>
      </header>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Classes today" value={todayClasses.length} icon={UserCheck} accent="lavender" />
        <StatCard label="My students" value={myStudents.length} icon={Users} accent="mint" />
        <StatCard label="Attendance preview" value="94%" icon={UserCheck} accent="sky" />
        <StatCard label="To review" value={toReview.length} icon={ClipboardList} accent="peach" />
      </div>

      <section>
        <SectionHeader title="Quick actions" />
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          {quickActions.map((a, i) => (
            <motion.button
              key={a.title}
              initial={{ opacity: 0, y: 12 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.06, ease: EASE }}
              whileHover={{ y: -2 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => (window.location.href = a.href)}
              className={cn(
                "flex flex-col items-start gap-5 rounded-2xl border border-border/60 bg-card p-4 text-left transition-[box-shadow,transform] duration-200 ease-ease-out-expo hover:shadow-soft",
              )}
            >
              <span className={cn("flex h-9 w-9 items-center justify-center rounded-xl", accentChip[a.accent])}>
                <a.icon className="h-4 w-4" />
              </span>
              <span className="text-sm font-semibold">{a.title}</span>
            </motion.button>
          ))}
        </div>
      </section>

      <div className="grid gap-6 lg:grid-cols-3">
        <section className="lg:col-span-2">
          <SectionHeader title="Today's classes" subtitle="In chronological order" action={<Link href="/teacher/schedule" className="text-sm font-medium text-primary">Schedule</Link>} />
          {todayClasses.length === 0 ? (
            <div className="rounded-3xl border border-dashed border-border/70 bg-secondary/30 p-10 text-center">
              <span className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-card text-muted-foreground shadow-xs ring-1 ring-border/50">
                <Music className="h-5 w-5" />
              </span>
              <p className="text-sm font-medium">No classes today</p>
              <p className="text-xs text-muted-foreground">Enjoy the break or catch up on feedback.</p>
            </div>
          ) : (
            <div className="relative space-y-3 before:absolute before:bottom-4 before:left-[18px] before:top-4 before:w-px before:bg-border">
              {todayClasses.map((c, i) => (
                <motion.div
                  key={c.id}
                  initial={{ opacity: 0, x: -8 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.05 }}
                  className="relative flex items-center gap-4 rounded-3xl border bg-card p-4 shadow-card"
                >
                  <div className="relative z-10 flex h-9 w-9 items-center justify-center rounded-full border-4 border-background bg-primary text-[10px] font-bold text-primary-foreground">
                    {formatTime(c.start_time)}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold">{c.title}</p>
                    <p className="text-xs text-muted-foreground">
                      {c.student_ids.length} student{c.student_ids.length === 1 ? "" : "s"} · {c.room ?? c.mode}
                    </p>
                  </div>
                  <Badge variant={c.mode === "online" ? "mint" : "lavender"}>{c.mode}</Badge>
                </motion.div>
              ))}
            </div>
          )}
        </section>

        <section>
          <SectionHeader title="Needs attention" />
          <div className="space-y-3">
            {lowPractice.length > 0 && (
              <div className="surface p-4">
                <p className="text-caption text-muted-foreground">Low practice this week</p>
                {lowPractice.map((s) => (
                  <p key={s.id} className="mt-1 text-sm font-semibold">{s.full_name}</p>
                ))}
              </div>
            )}
            {toReview.length > 0 && (
              <div className="surface p-4">
                <p className="text-caption text-muted-foreground">Assignments awaiting review</p>
                {toReview.map((a) => (
                  <p key={a.id} className="mt-1 text-sm font-semibold">{a.title}</p>
                ))}
              </div>
            )}
            <div className="surface p-4">
              <p className="text-caption text-muted-foreground">Up next</p>
              <p className="mt-1 text-sm font-semibold">
                {todayClasses.length > 0 ? todayClasses[0].title : "No lessons"}
              </p>
              <Link href="/teacher/students" className="mt-2 inline-flex items-center gap-1 text-xs font-medium text-primary">
                Manage students <ArrowRight className="h-3 w-3" />
              </Link>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}