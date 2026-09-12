"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { ScheduleCalendar } from "@/components/calendar/schedule-calendar";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function StudentSchedulePage() {
  const { classes } = useAcademyData();
  const mine = classes.filter((c) => c.student_ids.includes("s1"));
  return (
    <div>
      <PageHeader title="Schedule" subtitle="Your weekly timetable." />
      <ScheduleCalendar classes={mine} />
    </div>
  );
}