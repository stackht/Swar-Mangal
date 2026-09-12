"use client";

import * as React from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import {
  Bell, Users, GraduationCap, Calendar, CreditCard,
  ArrowUpRight, ArrowDownRight, Music,
} from "lucide-react";
import { Area, AreaChart, ResponsiveContainer, Tooltip, XAxis } from "recharts";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { EASE, listVariants, itemVariants } from "@/lib/motion";
import { useAcademyData } from "@/hooks/use-academy-data";
import { formatTime } from "@/lib/utils/cn";

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

const revenueData = [
  { month: "Apr", value: 4200 },
  { month: "May", value: 4900 },
  { month: "Jun", value: 5300 },
  { month: "Jul", value: 5800 },
  { month: "Aug", value: 6400 },
  { month: "Sep", value: 6900 },
];

export default function AdminDashboard() {
  const { user } = useAuth();
  const { classes, students, teachers, payments, invoices } = useAcademyData();
  const todayClasses = classes.filter((c) => new Date(c.start_time).toDateString() === new Date().toDateString());
  const outstanding = invoices.filter((i) => i.status !== "paid").reduce((s, i) => s + Number(i.amount), 0);

  return (
    <div className="space-y-10">
      {/* HEADER */}
      <motion.header variants={listVariants} initial="hidden" animate="visible" className="flex items-center justify-between gap-4">
        <motion.div variants={itemVariants} className="flex items-center gap-3.5">
          <Avatar name={user?.full_name ?? "Marcus"} src={user?.avatar_url} size="lg" />
          <div>
            <p className="text-eyebrow">Admin</p>
            <h1 className="text-display text-primary">{greeting()}, {user?.full_name?.split(" ")[0] ?? "Marcus"}</h1>
          </div>
        </motion.div>
        <motion.div variants={itemVariants} className="flex gap-2">
          <Button variant="ghost" size="icon" asChild className="relative">
            <Link href="/admin/notifications"><Bell className="h-5 w-5" /></Link>
          </Button>
        </motion.div>
      </motion.header>

      {/* ACADEMY OVERVIEW */}
      <motion.div variants={listVariants} initial="hidden" animate="visible">
        <h3 className="text-eyebrow mb-3">Academy overview</h3>
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-violet-100 text-violet-600 dark:bg-violet-500/15 dark:text-violet-300"><Users className="h-4 w-4" /></div>
              <span className="flex items-center gap-0.5 text-xs font-medium text-emerald-600 dark:text-emerald-300"><ArrowUpRight className="h-3 w-3" />12%</span>
            </div>
            <p className="text-xl font-bold tabular-nums">{students.length}</p>
            <p className="text-caption text-muted-foreground mt-0.5">Students</p>
          </motion.div>

          <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-100 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-300"><GraduationCap className="h-4 w-4" /></div>
            </div>
            <p className="text-xl font-bold tabular-nums">{teachers.length}</p>
            <p className="text-caption text-muted-foreground mt-0.5">Teachers</p>
          </motion.div>

          <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-100 text-blue-600 dark:bg-blue-500/15 dark:text-blue-300"><Calendar className="h-4 w-4" /></div>
            </div>
            <p className="text-xl font-bold tabular-nums">{todayClasses.length}</p>
            <p className="text-caption text-muted-foreground mt-0.5">Classes today</p>
          </motion.div>

          <motion.div variants={itemVariants} className="rounded-2xl border border-border/50 bg-card p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-100 text-amber-600 dark:bg-amber-500/15 dark:text-amber-300"><CreditCard className="h-4 w-4" /></div>
              {outstanding > 0 && <span className="flex items-center gap-0.5 text-xs font-medium text-amber-600 dark:text-amber-300"><ArrowDownRight className="h-3 w-3" />${outstanding}</span>}
            </div>
            <p className="text-xl font-bold tabular-nums">${payments.reduce((s, p) => s + p.amount, 0)}</p>
            <p className="text-caption text-muted-foreground mt-0.5">Revenue</p>
          </motion.div>
        </div>
      </motion.div>

      {/* REVENUE CHART */}
      <section>
        <h3 className="text-eyebrow mb-3">Revenue trend</h3>
        <div className="rounded-2xl border border-border/50 bg-card p-5">
          <div className="h-44">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueData}>
                <defs>
                  <linearGradient id="admin-rev" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="hsl(262 80% 60%)" stopOpacity={0.3} />
                    <stop offset="100%" stopColor="hsl(262 80% 60%)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }} />
                <Tooltip contentStyle={{ borderRadius: 16, border: "1px solid hsl(var(--border))", fontSize: 12, background: "hsl(var(--card))" }} formatter={(v) => [`$${v}`, "revenue"]} />
                <Area type="monotone" dataKey="value" stroke="hsl(262 80% 60%)" strokeWidth={2.5} fill="url(#admin-rev)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </section>

      {/* TODAY'S SCHEDULE */}
      <section>
        <div className="flex items-end justify-between mb-3">
          <h3 className="text-eyebrow">Today{"'"}s schedule</h3>
          <Link href="/admin/schedule" className="text-xs font-medium text-primary hover:underline">View all</Link>
        </div>
        <div className="space-y-2">
          {todayClasses.map((c, i) => (
            <motion.div key={c.id} initial={{ opacity: 0, y: 8 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.05, ease: EASE }}
              className="flex items-center gap-4 rounded-2xl border border-border/50 bg-card p-4">
              <div className="text-center min-w-[52px]">
                <p className="text-sm font-bold tabular-nums">{formatTime(c.start_time).split(" ")[0]}</p>
                <p className="text-[10px] text-muted-foreground">{formatTime(c.start_time).split(" ")[1]}</p>
              </div>
              <div className="h-8 w-px bg-border/60" />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold">{c.title}</p>
                <p className="text-xs text-muted-foreground">{c.teacher_name} · {c.student_ids.length} students</p>
              </div>
              <Badge variant={c.mode === "online" ? "secondary" : "default"}>{c.mode}</Badge>
            </motion.div>
          ))}
          {todayClasses.length === 0 && (
            <p className="text-sm text-muted-foreground py-4 text-center">No classes scheduled for today.</p>
          )}
        </div>
      </section>

      {/* QUICK ACTIONS */}
      <section>
        <h3 className="text-eyebrow mb-3">Quick actions</h3>
        <div className="grid grid-cols-2 gap-3">
          {[
            { icon: <Users className="h-4 w-4" />, label: "Add Student", href: "/admin/students" },
            { icon: <GraduationCap className="h-4 w-4" />, label: "Add Teacher", href: "/admin/teachers" },
            { icon: <Music className="h-4 w-4" />, label: "Create Course", href: "/admin/courses" },
            { icon: <CreditCard className="h-4 w-4" />, label: "Manage Fees", href: "/admin/fees" },
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