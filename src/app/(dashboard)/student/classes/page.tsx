"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { ClassCard } from "@/components/dashboard/class-card";
import { EmptyState } from "@/components/dashboard/empty-state";
import { Button } from "@/components/ui/button";
import { CalendarX2 } from "lucide-react";

import { classes } from "@/lib/data/demo";

export default function StudentClassesPage() {
  const mine = classes.filter((c) => c.student_ids.includes("s1"));

  return (
    <div>
      <PageHeader title="My Classes" subtitle="Your scheduled lessons and courses." />

      {mine.length === 0 ? (
        <EmptyState
          icon={<CalendarX2 className="h-6 w-6" />}
          title="No upcoming classes"
          description="Your schedule is clear for now. Talk to your teacher to book your next lesson."
          action={<Button>Browse schedule</Button>}
        />
      ) : (
        <div className="space-y-8">
          <section>
            <SectionHeader title="Upcoming" subtitle="Your next lessons" />
            <div className="grid gap-4 md:grid-cols-2">
              {mine.map((c, i) => (
                <ClassCard key={c.id} cls={c} index={i} />
              ))}
            </div>
          </section>
        </div>
      )}
    </div>
  );
}