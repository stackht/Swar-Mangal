"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { ClassCard } from "@/components/dashboard/class-card";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function TeacherClassesPage() {
  const { classes, students } = useAcademyData();
  const mine = classes.filter((c) => c.teacher_id === "t1");
  const future = mine.filter((c) => new Date(c.start_time) >= new Date());
  const past = mine.filter((c) => new Date(c.start_time) < new Date());

  return (
    <div>
      <PageHeader title="My Classes" subtitle="Classes you teach." />

      <section className="mb-8">
        <SectionHeader title="Upcoming" subtitle={`${future.length} scheduled`} />
        <div className="grid gap-4 md:grid-cols-2">
          {future.map((c, i) => <ClassCard key={c.id} cls={c} index={i} />)}
        </div>
      </section>

      <section>
        <SectionHeader title="Class roster summary" />
        <div className="grid gap-4 md:grid-cols-2">
          {mine.map((c) => {
            const roster = c.student_ids.map((id) => students.find((s) => s.id === id)!).filter(Boolean);
            return (
              <Card key={c.id}>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-sm">{c.title}</CardTitle>
                    <Badge variant="lavender">{roster.length} students</Badge>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="flex flex-wrap gap-2">
                    {roster.map((s) => (
                      <span key={s.id} className="rounded-full bg-secondary px-3 py-1 text-xs font-medium">
                        {s.full_name}
                      </span>
                    ))}
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </section>

      {past.length > 0 && (
        <div className="mt-8">
          <SectionHeader title="Past classes" />
          <div className="grid gap-4 md:grid-cols-2">
            {past.map((c, i) => <ClassCard key={c.id} cls={c} index={i} />)}
          </div>
        </div>
      )}
    </div>
  );
}