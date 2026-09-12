"use client";

import * as React from "react";
import { Plus } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { ScheduleCalendar } from "@/components/calendar/schedule-calendar";
import { Button } from "@/components/ui/button";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function AdminSchedulePage() {
  const { classes } = useAcademyData();
  return (
    <div>
      <PageHeader
        title="Schedule"
        subtitle="Full academy timetable."
        actions={
          <Button onClick={() => toast.success("Class creation flow opened")}>
            <Plus className="h-4 w-4" /> New class
          </Button>
        }
      />
      <ScheduleCalendar classes={classes} admin />
    </div>
  );
}