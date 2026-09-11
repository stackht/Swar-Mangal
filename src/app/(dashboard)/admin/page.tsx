"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowRight, CreditCard, DollarSign, GraduationCap, TrendingUp, UserCheck, Users } from "lucide-react";
import { Area, AreaChart, Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { SectionHeader } from "@/components/dashboard/section-header";
import { StatCard } from "@/components/dashboard/stat-card";

import { classes, students, teachers, payments, invoices } from "@/lib/data/demo";

const studentGrowth = [
  { month: "Apr", students: 42 },
  { month: "May", students: 51 },
  { month: "Jun", students: 58 },
  { month: "Jul", students: 63 },
  { month: "Aug", students: 71 },
  { month: "Sep", students: 78 },
];

const attendanceData = [
  { week: "W1", rate: 88 },
  { week: "W2", rate: 90 },
  { week: "W3", rate: 86 },
  { week: "W4", rate: 92 },
  { week: "W5", rate: 94 },
];

const revenueData = [
  { month: "Apr", revenue: 4200 },
  { month: "May", revenue: 4900 },
  { month: "Jun", revenue: 5300 },
  { month: "Jul", revenue: 5800 },
  { month: "Aug", revenue: 6400 },
  { month: "Sep", revenue: 6900 },
];

export default function AdminDashboard() {
  const { user } = useAuth();
  const todayClasses = classes.filter((c) => new Date(c.start_time).toDateString() === new Date().toDateString());
  const revenue = invoices.reduce((s, i) => (i.status === "paid" ? s + Number(i.amount) : s), 0);
  const pending = invoices.filter((i) => i.status !== "paid").reduce((s, i) => s + Number(i.amount), 0);

  return (
    <div className="space-y-8">
      <header className="flex flex-wrap items-start justify-between gap-4">
        <div className="flex items-center gap-3">
          <Avatar name={user?.full_name ?? "Marcus Reed"} src={user?.avatar_url} size="lg" />
          <div>
            <p className="text-xs font-medium text-muted-foreground">Admin</p>
            <h1 className="text-2xl font-bold tracking-tight">Good morning, {user?.full_name?.split(" ")[0] ?? "Marcus"}</h1>
            <p className="text-sm text-muted-foreground">Here is what is happening at the academy today.</p>
          </div>
        </div>
        <Button asChild>
          <Link href="/admin/students"><Users className="h-4 w-4" /> Manage students</Link>
        </Button>
      </header>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Total students" value={students.length} icon={Users} accent="lavender" delta={12} />
        <StatCard label="Active teachers" value={teachers.length} icon={GraduationCap} accent="mint" delta={8} />
        <StatCard label="Classes today" value={todayClasses.length} icon={UserCheck} accent="sky" />
        <StatCard label="Monthly revenue" value={`$${revenue}`} icon={DollarSign} accent="peach" delta={10} />
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <section className="rounded-3xl border bg-card p-5 shadow-card">
          <p className="text-sm font-medium text-muted-foreground">Student growth</p>
          <div className="mt-2 h-44">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={studentGrowth}>
                <defs>
                  <linearGradient id="growth" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#8d6bf6" stopOpacity={0.5} />
                    <stop offset="100%" stopColor="#8d6bf6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <Area type="monotone" dataKey="students" stroke="#8d6bf6" strokeWidth={2.5} fill="url(#growth)" />
                <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: "hsl(220 12% 46%)" }} />
                <YAxis hide />
                <Tooltip contentStyle={{ borderRadius: 16, border: "1px solid hsl(220 18% 90%)", fontSize: 12 }} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </section>

        <section className="rounded-3xl border bg-card p-5 shadow-card">
          <p className="text-sm font-medium text-muted-foreground">Attendance rate</p>
          <div className="mt-2 h-44">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={attendanceData}>
                <XAxis dataKey="week" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: "hsl(220 12% 46%)" }} />
                <YAxis hide domain={[0, 100]} />
                <Tooltip contentStyle={{ borderRadius: 16, border: "1px solid hsl(220 18% 90%)", fontSize: 12 }} />
                <Bar dataKey="rate" fill="#2dbd7f" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </section>

        <section className="rounded-3xl border bg-card p-5 shadow-card">
          <p className="text-sm font-medium text-muted-foreground">Revenue</p>
          <div className="mt-2 h-44">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenueData}>
                <defs>
                  <linearGradient id="rev" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#ff8f3f" stopOpacity={0.5} />
                    <stop offset="100%" stopColor="#ff8f3f" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <Area type="monotone" dataKey="revenue" stroke="#ff8f3f" strokeWidth={2.5} fill="url(#rev)" />
                <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: "hsl(220 12% 46%)" }} />
                <YAxis hide />
                <Tooltip contentStyle={{ borderRadius: 16, border: "1px solid hsl(220 18% 90%)", fontSize: 12 }} formatter={(v) => [`$${v}`, "revenue"]} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </section>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <section>
          <SectionHeader title="Today's schedule" action={<Link href="/admin/schedule" className="text-sm font-medium text-primary">Schedule</Link>} />
          <div className="space-y-2">
            {todayClasses.map((c, i) => (
              <motion.div
                key={c.id}
                initial={{ opacity: 0, x: -8 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05 }}
                className="flex items-center gap-3 rounded-2xl border bg-card p-4 shadow-card"
              >
                <div className="flex h-10 w-10 items-center justify-center rounded-2xl text-sm font-bold" style={{ backgroundColor: `${c.color}22`, color: c.color }}>
                  {new Date(c.start_time).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold">{c.title}</p>
                  <p className="text-xs text-muted-foreground">{c.teacher_name} · {c.student_ids.length} students</p>
                </div>
                <Badge variant={c.mode === "online" ? "mint" : "lavender"}>{c.mode}</Badge>
              </motion.div>
            ))}
          </div>
        </section>

        <section>
          <SectionHeader title="Recent payments" action={<Link href="/admin/fees" className="text-sm font-medium text-primary">Fees</Link>} />
          <div className="space-y-2">
            {payments.map((p, i) => (
              <motion.div
                key={p.id}
                initial={{ opacity: 0, x: -8 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05 }}
                className="flex items-center gap-3 rounded-2xl border bg-card p-4 shadow-card"
              >
                <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-mint-100 text-mint-700 dark:bg-mint-500/15 dark:text-mint-300">
                  <CreditCard className="h-5 w-5" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium">{p.student_name}</p>
                  <p className="text-xs text-muted-foreground">{p.method} · {new Date(p.date).toLocaleDateString()}</p>
                </div>
                <span className="text-sm font-bold text-mint-700 dark:text-mint-300">+${p.amount}</span>
              </motion.div>
            ))}
          </div>
          {pending > 0 && (
            <div className="mt-4 flex items-center gap-3 rounded-2xl bg-peach-100 p-4 dark:bg-peach-500/15">
              <TrendingUp className="h-5 w-5 text-peach-700 dark:text-peach-300" />
              <p className="text-sm text-peach-800 dark:text-peach-200">${pending} in pending fees across {invoices.filter((i) => i.status !== "paid").length} invoices.</p>
              <ArrowRight className="ml-auto h-4 w-4 text-peach-700 dark:text-peach-300" />
            </div>
          )}
        </section>
      </div>
    </div>
  );
}