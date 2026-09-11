"use client";

import { Bell, CalendarDays, ClipboardList, Flame, Music, Target } from "lucide-react";
import Link from "next/link";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { SectionHeader } from "@/components/dashboard/section-header";
import { GradientCard } from "@/components/dashboard/gradient-card";
import { StatCard } from "@/components/dashboard/stat-card";
import { ProgressRing } from "@/components/dashboard/progress-ring";
import { Badge } from "@/components/ui/badge";

import { practice, attendance, progress, classes, invoices } from "@/lib/data/demo";

export default function ParentDashboard() {
  const { user } = useAuth();
  const child = { name: "Aarav Sharma", instrument: "Piano", level: "Grade 3" };
  const weeklyMins = practice.filter((p) => p.student_id === "s1").reduce((s, p) => s + p.minutes, 0);
  const nextClass = classes.find((c) => c.student_ids.includes("s1"))!;
  const balance = invoices.filter((i) => i.student_id === "s1" && i.status !== "paid").reduce((s, i) => s + Number(i.amount), 0);

  return (
    <div className="space-y-8">
      <header className="flex flex-wrap items-start justify-between gap-4">
        <div className="flex items-center gap-3">
          <Avatar name={user?.full_name ?? "Rohan Sharma"} src={user?.avatar_url} size="lg" />
          <div>
            <p className="text-xs font-medium text-muted-foreground">Parent · of {child.name}</p>
            <h1 className="text-2xl font-bold tracking-tight">Hello, {user?.full_name?.split(" ")[0] ?? "Rohan"}</h1>
            <p className="text-sm text-muted-foreground">{`Here is ${child.name.split(" ")[0]}'s progress.`}</p>
          </div>
        </div>
        <Button variant="ghost" size="icon" asChild>
          <Link href="/parent/notifications"><Bell className="h-5 w-5" /></Link>
        </Button>
      </header>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Practice this week" value={`${weeklyMins} min`} icon={Flame} accent="lavender" />
        <StatCard label="Attendance" value="94%" icon={Target} accent="mint" />
        <StatCard label="Skill score" value={`${progress.overall}%`} icon={Music} accent="peach" />
        <StatCard label="Fees due" value={`$${balance}`} icon={Target} accent="sky" />
      </div>

      <GradientCard gradient="navy" className="p-6">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <Badge className="bg-lavender-400/20 text-lavender-100">Next class</Badge>
            <h2 className="mt-3 text-xl font-bold">{nextClass.title}</h2>
            <p className="mt-1 text-sm text-white/70">
              Today · {new Date(nextClass.start_time).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })} · with {nextClass.teacher_name}
            </p>
          </div>
          <Button className="bg-white text-navy-900 hover:bg-white/90" asChild>
            <Link href="/parent/attendance"><CalendarDays className="h-4 w-4" /> View attendance</Link>
          </Button>
        </div>
      </GradientCard>

      <section>
        <SectionHeader title="Child's activity" />
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="surface p-5">
            <p className="text-eyebrow">Practice this week</p>
            <p className="text-h1 mt-2">{weeklyMins} min</p>
            <div className="mt-4 flex items-center gap-4">
              <ProgressRing value={(weeklyMins / 150) * 100} size={70} stroke={8} color="hsl(253 72% 60%)" trackColor="hsl(var(--secondary))" label={`${Math.round((weeklyMins / 150) * 100)}%`} sublabel="goal" />
              <p className="text-body-sm text-muted-foreground">of a 150 min weekly goal</p>
            </div>
          </div>
          <div className="surface p-5">
            <p className="text-eyebrow">Instrument progress</p>
            <p className="text-h1 mt-2">{child.instrument}</p>
            <p className="text-body-sm text-muted-foreground">{child.level} · {progress.overall}% overall skill</p>
            <div className="mt-4 flex flex-wrap gap-2">
              {progress.categories.slice(0, 4).map((c) => (
                <span key={c.name} className="rounded-full bg-secondary px-3 py-1 text-xs font-medium text-muted-foreground">{c.name} {c.score}</span>
              ))}
            </div>
          </div>
        </div>
      </section>

      <div className="grid gap-6 lg:grid-cols-2">
        <section>
          <SectionHeader title="Recent lessons" />
          <div className="space-y-2">
            {attendance.filter((a) => a.student_id === "s1").slice(0, 3).map((a) => (
              <div key={a.id} className="flex items-center gap-3 rounded-2xl border bg-card p-4 shadow-card">
                <Avatar name={child.name} size="sm" />
                <div className="flex-1">
                  <p className="text-sm font-medium">{child.name}</p>
                  <p className="text-xs text-muted-foreground">{new Date(a.date).toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" })}</p>
                </div>
                <Badge variant={a.status === "present" ? "mint" : a.status === "late" ? "lavender" : "peach"}>{a.status}</Badge>
              </div>
            ))}
          </div>
        </section>
        <section>
          <SectionHeader title="Assignments due" />
          <div className="flex flex-col items-center rounded-3xl border border-dashed border-border/70 bg-secondary/30 p-10 text-center">
            <span className="mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-card text-muted-foreground shadow-xs ring-1 ring-border/50">
              <ClipboardList className="h-5 w-5" />
            </span>
            <p className="text-sm font-medium">2 assignments in progress</p>
            <p className="text-xs text-muted-foreground">1 due this week — Fur Elise Section A</p>
          </div>
        </section>
      </div>
    </div>
  );
}