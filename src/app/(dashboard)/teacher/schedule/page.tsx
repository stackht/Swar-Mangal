"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { ScheduleCalendar } from "@/components/calendar/schedule-calendar";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function TeacherSchedulePage() {
  const { classes } = useAcademyData();
  const mine = classes.filter((c) => c.teacher_id === "t1");
  return (
    <div>
      <PageHeader title="Schedule" subtitle="Your teaching timetable." />
      <ScheduleCalendar classes={mine} />
    </div>
  );
}