"use client";

import { useQuery } from "@tanstack/react-query";
import { useMemo } from "react";

import * as demo from "@/lib/data/demo";
import type { AcademyDataset } from "@/lib/db/queries";

interface DataResponse {
  data: AcademyDataset | null;
  demo: boolean;
}

async function fetchDataset(): Promise<DataResponse> {
  const res = await fetch("/api/data", { cache: "no-store" });
  if (!res.ok) return { data: null, demo: true };
  return res.json();
}

function demoDataset(): AcademyDataset {
  return {
    instruments: demo.instruments,
    teachers: demo.teachers,
    students: demo.students,
    classes: demo.classes,
    attendance: demo.attendance,
    practice: demo.practice,
    assignments: demo.assignments,
    resources: demo.resources,
    progress: demo.progress,
    skillCategories: demo.skillCategories,
    messages: demo.messages,
    threads: demo.threads,
    notifications: demo.notifications,
    announcements: demo.announcements,
    invoices: demo.invoices,
    payments: demo.payments,
    achievements: demo.achievements,
    feedback: demo.feedback,
    weeklyHours: demo.weeklyHours,
  };
}

export function useAcademyData() {
  const { data, refetch, isFetching } = useQuery<DataResponse>({
    queryKey: ["academyData"],
    queryFn: fetchDataset,
    staleTime: 30_000,
  });

  const pane = useMemo(() => {
    if (!data) return { dataset: demoDataset(), isDemo: true, isLoading: true };
    return data.demo || !data.data
      ? { dataset: demoDataset(), isDemo: true, isLoading: false }
      : { dataset: data.data, isDemo: false, isLoading: false };
  }, [data]);

  return {
    ...pane.dataset,
    isDemo: pane.isDemo,
    isLoading: pane.isLoading,
    refetch,
    isFetching,
  };
}