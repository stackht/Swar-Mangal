"use client";

import * as React from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import {
  Bell, Clock, CheckCircle2, AlertCircle, Music,
  ArrowRight, Users, MessageSquare, Plus,
} from "lucide-react";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { SectionHeader } from "@/components/dashboard/section-header";
import { FrequencyBars } from "@/components/music/frequency-bars";
import { EASE, listVariants, itemVariants } from "@/lib/motion";
import { classes, students, practice, assignments } from "@/lib/data/demo";
import { formatTime } from "@/lib/utils/cn";

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

export default function TeacherDashboard() {
  const { user } = useAuth();
  const todayClasses = classes
    .filter((c) => c.teacher_id === "t1" && new Date(c.start_time).toDateString() === new Date().toDateString())
    .sort((a, b) => +new Date(a.start_time) - +new Date(b.start_time));
  const myStudents = students.filter((s) => classes.some((c) => c.teacher_id === "t1" && c.student_ids.includes(s.id)));
  const lowPractice = myStudents.filter((s) => practice.filter((p) => p.student_id === s.id && new Date(p.date) >= new Date(Date.now() - 7 * 864e5)).reduce((x, p) => x + p.minutes, 0) < 30);
  const pendingReview = assignments.filter((a) => a.teacher_id === "t1" && a.status === "submitted");

  return (
    <div className="space-y-10">
      {/* HEADER */}
      <motion.header variants={listVariants} initial="hidden" animate="visible" className="flex items-center justify-between gap-4">
        <motion.div variants={itemVariants} className="flex items-center gap-3.5">
          <Avatar name={user?.full_name ?? "Sarah"} src={user?.avatar_url} size="lg" />
          <div>
            <p className="text-eyebrow">Teacher · Piano</p>
            <h1 className="text-display text-primary">{greeting()}, {user?.full_name?.split(" ")[0] ?? "Sarah"}</h1>
          </div>
        </motion.div>
        <motion.div variants={itemVariants}>
          <Button variant="ghost" size="icon" asChild className="relative">
            <Link href="/teacher/notifications">
              <Bell className="h-5 w-5" />
              <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-violet-500" />
            </Link>
          </Button>
        </motion.div>
      </motion.header>

      {/* QUICK STATS */}
      <motion.div variants={listVariants} initial="hidden" animate="visible" className="grid grid-cols-3 gap-3">
        <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4 text-center">
          <p className="text-2xl font-bold tabular-nums">{todayClasses.length}</p>
          <p className="text-caption text-muted-foreground mt-0.5">Classes today</p>
        </motion.div>
        <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4 text-center">
          <p className="text-2xl font-bold tabular-nums">{myStudents.length}</p>
          <p className="text-caption text-muted-foreground mt-0.5">Students</p>
        </motion.div>
        <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4 text-center">
          <p className="text-2xl font-bold tabular-nums text-violet-600 dark:text-violet-300">{pendingReview.length}</p>
          <p className="text-caption text-muted-foreground mt-0.5">To review</p>
        </motion.div>
      </motion.div>

      {/* TODAY'S CLASSES — timeline */}
      <section>
        <div className="flex items-end justify-between mb-4">
          <h3 className="text-eyebrow">Today{"'"}s teaching</h3>
          <Link href="/teacher/schedule" className="text-xs font-medium text-primary hover:underline">Schedule</Link>
        </div>
        {todayClasses.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-border/50 bg-secondary/30 p-10 text-center">
            <Music className="mx-auto mb-2 h-6 w-6 text-muted-foreground/60" />
            <p className="text-sm font-medium">No classes today</p>
            <p className="text-xs text-muted-foreground">A free day — catch up on feedback.</p>
          </div>
        ) : (
          <div className="space-y-2">
            {todayClasses.map((c, i) => (
              <motion.div key={c.id} initial={{ opacity: 0, x: -8 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.05, ease: EASE }}
                className="flex items-center gap-4 rounded-2xl border border-border/50 bg-card p-4 hover:shadow-soft transition-shadow">
                <div className="text-center min-w-[52px]">
                  <p className="text-sm font-bold tabular-nums">{formatTime(c.start_time).split(" ")[0]}</p>
                  <p className="text-[10px] text-muted-foreground">{formatTime(c.start_time).split(" ")[1]}</p>
                </div>
                <div className="h-8 w-px bg-border/60" />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold">{c.title}</p>
                  <p className="text-xs text-muted-foreground">{c.student_ids.length} students · {c.room ?? c.mode}</p>
                </div>
                <div className="h-8 w-16 opacity-50"><FrequencyBars bars={10} playing={false} /></div>
                <Badge variant={c.mode === "online" ? "secondary" : "default"}>{c.mode}</Badge>
              </motion.div>
            ))}
          </div>
        )}
      </section>

      {/* STUDENTS NEEDING ATTENTION */}
      <section>
        <SectionHeader title="Students needing attention" />
        <div className="space-y-2">
          {lowPractice.length > 0 && lowPractice.map((s) => (
            <div key={s.id} className="flex items-center gap-3 rounded-2xl border border-border/50 bg-card p-4">
              <Avatar name={s.full_name} />
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium">{s.full_name}</p>
                <p className="text-xs text-orange-600 dark:text-orange-300 flex items-center gap-1"><AlertCircle className="h-3 w-3" /> Low practice this week</p>
              </div>
              <Button variant="ghost" size="sm" asChild><Link href="/teacher/students">View</Link></Button>
            </div>
          ))}
          {pendingReview.length > 0 && pendingReview.slice(0, 2).map((a) => (
            <div key={a.id} className="flex items-center gap-3 rounded-2xl border border-border/50 bg-card p-4">
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-violet-100 text-violet-600 dark:bg-violet-500/15 dark:text-violet-300">
                <CheckCircle2 className="h-4 w-4" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium">{a.title}</p>
                <p className="text-xs text-muted-foreground">Submitted — review pending</p>
              </div>
              <Button variant="ghost" size="sm" asChild><Link href="/teacher/assignments">Review</Link></Button>
            </div>
          ))}
          {lowPractice.length === 0 && pendingReview.length === 0 && (
            <p className="text-sm text-muted-foreground py-2">All students on track — great work.</p>
          )}
        </div>
      </section>

      {/* QUICK ACTIONS */}
      <section>
        <h3 className="text-eyebrow mb-3">Quick actions</h3>
        <div className="grid grid-cols-2 gap-3">
          {[
            { icon: <UserCheck className="h-4 w-4" />, label: "Attendance", href: "/teacher/attendance" },
            { icon: <Plus className="h-4 w-4" />, label: "New Assignment", href: "/teacher/assignments" },
            { icon: <MessageSquare className="h-4 w-4" />, label: "Message Students", href: "/teacher/messages" },
            { icon: <Upload className="h-4 w-4" />, label: "Upload Material", href: "/teacher/library" },
          ].map((a) => (
            <Link key={a.label} href={a.href}
              className="flex items-center gap-3 rounded-2xl border border-border/50 bg-card p-4 text-left transition-shadow hover:shadow-soft">
              <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-violet-100/80 text-violet-600 dark:bg-violet-500/15 dark:text-violet-300">{a.icon}</span>
              <span className="text-sm font-medium">{a.label}</span>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}

function UserCheck(props: React.SVGProps<SVGSVGElement>) {
  return <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><polyline points="16 11 18 13 22 9"/></svg>;
}
function Upload(props: React.SVGProps<SVGSVGElement>) {
  return <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" x2="12" y1="3" y2="15"/></svg>;
}