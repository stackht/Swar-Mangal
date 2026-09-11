"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { GradientCard } from "@/components/dashboard/gradient-card";
import { ProgressRing } from "@/components/dashboard/progress-ring";
import { Progress } from "@/components/ui/progress";

import { progress } from "@/lib/data/demo";

export default function ParentProgressPage() {
  return (
    <div>
      <PageHeader title="Progress" subtitle="Aarav's musical development." />
      <GradientCard gradient="navy" className="mb-6 flex items-center gap-5">
        <ProgressRing value={progress.overall} size={110} stroke={11} color="#8d6bf6" trackColor="rgba(255,255,255,0.15)" label={`${progress.overall}`} sublabel="overall" />
        <div>
          <p className="text-lg font-bold">{progress.level}</p>
          <p className="text-sm text-white/70">{progress.instrument}</p>
        </div>
      </GradientCard>
      <section>
        <SectionHeader title="Skill areas" />
        <div className="grid gap-3 sm:grid-cols-2">
          {progress.categories.map((c) => (
            <div key={c.name} className="rounded-2xl border bg-card p-4 shadow-card">
              <div className="mb-2 flex justify-between text-sm">
                <span className="font-medium">{c.name}</span>
                <span className="text-muted-foreground">{c.score}/100</span>
              </div>
              <Progress value={c.score} indicatorClassName="bg-gradient-to-r from-lavender-400 to-mint-400" />
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}