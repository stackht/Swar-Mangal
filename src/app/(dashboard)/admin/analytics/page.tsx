"use client";

import { motion } from "framer-motion";
import { Download, Upload, Users } from "lucide-react";
import { Area, AreaChart, Bar, BarChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis, Cell } from "recharts";

import { PageHeader } from "@/components/dashboard/page-header";
import { StatCard } from "@/components/dashboard/stat-card";

const enrollment = [
  { month: "Apr", students: 42, classes: 46 },
  { month: "May", students: 51, classes: 54 },
  { month: "Jun", students: 58, classes: 62 },
  { month: "Jul", students: 63, classes: 68 },
  { month: "Aug", students: 71, classes: 74 },
  { month: "Sep", students: 78, classes: 82 },
];

const instrumentMix = [
  { name: "Piano", value: 38, color: "#8d6bf6" },
  { name: "Guitar", value: 24, color: "#2dbd7f" },
  { name: "Vocals", value: 16, color: "#ff8f3f" },
  { name: "Violin", value: 12, color: "#5b8def" },
  { name: "Drums", value: 6, color: "#e0608a" },
  { name: "Other", value: 4, color: "#a7b7cd" },
];

const classUtil = [
  { name: "Mon", utilization: 72 },
  { name: "Tue", utilization: 68 },
  { name: "Wed", utilization: 84 },
  { name: "Thu", utilization: 76 },
  { name: "Fri", utilization: 58 },
  { name: "Sat", utilization: 92 },
];

export default function AdminAnalyticsPage() {
  return (
    <div>
      <PageHeader title="Analytics" subtitle="Academy performance at a glance." />

      <div className="mb-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Student growth" value="85%" icon={Users} accent="lavender" delta={12} />
        <StatCard label="Attendance" value="91%" icon={Download} accent="mint" />
        <StatCard label="Class utilization" value="75%" icon={Upload} accent="sky" />
        <StatCard label="Retention" value="93%" icon={Download} accent="peach" />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <section className="rounded-3xl border bg-card p-5 shadow-card">
          <p className="text-sm font-medium text-muted-foreground">Enrollment vs classes</p>
          <div className="mt-2 h-60">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={enrollment}>
                <defs>
                  <linearGradient id="e1" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#8d6bf6" stopOpacity={0.5} />
                    <stop offset="100%" stopColor="#8d6bf6" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="e2" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#2dbd7f" stopOpacity={0.4} />
                    <stop offset="100%" stopColor="#2dbd7f" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: "hsl(220 12% 46%)" }} />
                <YAxis hide />
                <Tooltip contentStyle={{ borderRadius: 16, border: "1px solid hsl(220 18% 90%)", fontSize: 12 }} />
                <Area type="monotone" dataKey="students" stroke="#8d6bf6" strokeWidth={2.5} fill="url(#e1)" />
                <Area type="monotone" dataKey="classes" stroke="#2dbd7f" strokeWidth={2.5} fill="url(#e2)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </section>

        <section className="rounded-3xl border bg-card p-5 shadow-card">
          <p className="text-sm font-medium text-muted-foreground">Students by instrument</p>
          <div className="mt-2 h-60">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={instrumentMix} dataKey="value" nameKey="name" innerRadius={55} outerRadius={85} paddingAngle={3}>
                  {instrumentMix.map((s) => <Cell key={s.name} fill={s.color} />)}
                </Pie>
                <Tooltip contentStyle={{ borderRadius: 16, border: "1px solid hsl(220 18% 90%)", fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
            <div className="flex flex-wrap justify-center gap-2">
              {instrumentMix.map((s) => (
                <span key={s.name} className="flex items-center gap-1.5 text-xs text-muted-foreground">
                  <span className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: s.color }} /> {s.name} {s.value}%
                </span>
              ))}
            </div>
          </div>
        </section>

        <section className="rounded-3xl border bg-card p-5 shadow-card">
          <p className="text-sm font-medium text-muted-foreground">Class utilization by day</p>
          <div className="mt-2 h-52">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={classUtil}>
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: "hsl(220 12% 46%)" }} />
                <YAxis hide domain={[0, 100]} />
                <Tooltip contentStyle={{ borderRadius: 16, border: "1px solid hsl(220 18% 90%)", fontSize: 12 }} formatter={(v) => [`${v}%`, "utilization"]} />
                <Bar dataKey="utilization" radius={[8, 8, 0, 0]}>
                  {classUtil.map((d, i) => <Cell key={i} fill={["#8d6bf6", "#2dbd7f", "#ff8f3f", "#5b8def"][i % 4]} />)}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </section>

        <section className="rounded-3xl border bg-card p-5 shadow-card">
          <p className="text-sm font-medium text-muted-foreground">Top insights</p>
          <div className="mt-3 space-y-3">
            {[
              "Saturday is the busiest day — 92% studio utilization.",
              "Piano remains the most popular instrument (38% of students).",
              "Graduated 6 students to the next grade this quarter.",
            ].map((t, i) => (
              <motion.div key={i} initial={{ opacity: 0, x: -8 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.06 }} className="flex items-start gap-3 rounded-2xl bg-secondary/60 p-4">
                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary text-xs font-bold text-primary-foreground">{i + 1}</span>
                <p className="text-sm">{t}</p>
              </motion.div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}