"use client";

import { motion } from "framer-motion";
import { TrendingUp } from "lucide-react";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { Avatar } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";

import { students, progress } from "@/lib/data/demo";

const chartData = [
  { month: "Apr", aarav: 52, kai: 48 },
  { month: "May", aarav: 58, kai: 53 },
  { month: "Jun", aarav: 62, kai: 57 },
  { month: "Jul", aarav: 60, kai: 60 },
  { month: "Aug", aarav: 67, kai: 63 },
];

export default function TeacherProgressPage() {
  const myStudents = students.filter((s) => ["s1", "s3", "s2", "s10"].includes(s.id));

  return (
    <div>
      <PageHeader title="Student Progress" subtitle="Skill growth across your studio." />

      <div className="mb-8 rounded-3xl border bg-card p-5 shadow-card">
        <p className="text-sm font-medium text-muted-foreground">Skill score trend</p>
        <div className="mt-2 h-56">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: "hsl(220 12% 46%)" }} />
              <YAxis hide domain={[0, 100]} />
              <Tooltip contentStyle={{ borderRadius: 16, border: "1px solid hsl(220 18% 90%)", fontSize: 12 }} />
              <Line type="monotone" dataKey="aarav" name="Aarav" stroke="#8d6bf6" strokeWidth={2.5} dot={{ r: 3 }} />
              <Line type="monotone" dataKey="kai" name="Kai" stroke="#2dbd7f" strokeWidth={2.5} dot={{ r: 3 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <section>
        <SectionHeader title="Class overview" />
        <div className="space-y-3">
          {myStudents.map((s, i) => (
            <motion.div
              key={s.id}
              initial={{ opacity: 0, y: 8 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.04 }}
              className="flex items-center gap-4 rounded-2xl border bg-card p-4 shadow-card"
            >
              <Avatar name={s.full_name} />
              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between">
                  <p className="text-sm font-semibold">{s.full_name}</p>
                  <span className="flex items-center gap-1 text-xs text-mint-700 dark:text-mint-300">
                    <TrendingUp className="h-3 w-3" /> {s.level}
                  </span>
                </div>
                <div className="mt-2 flex items-center gap-3">
                  <Progress value={(s.id === "s1" ? 67 : 58) + (s.id === "s10" ? 11 : 0)} className="flex-1" indicatorClassName="bg-gradient-to-r from-lavender-400 to-mint-400" />
                  <Badge variant="secondary">{progress.categories[0].score + (s.id === "s1" ? 11 : 0)}/100</Badge>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  );
}