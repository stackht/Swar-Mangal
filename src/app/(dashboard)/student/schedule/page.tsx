"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { ScheduleCalendar } from "@/components/calendar/schedule-calendar";

import { classes } from "@/lib/data/demo";

export default function StudentSchedulePage() {
  const mine = classes.filter((c) => c.student_ids.includes("s1"));
  return (
    <div>
      <PageHeader title="Schedule" subtitle="Your weekly timetable." />
      <ScheduleCalendar classes={mine} />
    </div>
  );
}