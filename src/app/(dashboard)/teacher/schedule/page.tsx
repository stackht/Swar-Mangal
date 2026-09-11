"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { ScheduleCalendar } from "@/components/calendar/schedule-calendar";

import { classes } from "@/lib/data/demo";

export default function TeacherSchedulePage() {
  const mine = classes.filter((c) => c.teacher_id === "t1");
  return (
    <div>
      <PageHeader title="Schedule" subtitle="Your teaching timetable." />
      <ScheduleCalendar classes={mine} />
    </div>
  );
}