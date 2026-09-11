import { isSupabaseConfigured } from "@/lib/supabase/client";
import * as demo from "@/lib/data/demo";

export const dataMode = isSupabaseConfigured ? "supabase" : "demo";

export {
  instruments,
  teachers,
  students,
  classes,
  attendance,
  practice,
  assignments,
  resources,
  progress,
  messages,
  threads,
  notifications,
  announcements,
  invoices,
  payments,
  achievements,
  feedback,
  activity,
  skillCategories,
  weeklyHours,
  attendanceStatusLegend,
} from "@/lib/data/demo";

// Re-export narrowing: when Supabase is configured, these would be served by
// tanstack-query against the live DB. For the demo fallback we serve local
// data. ponytail: swap each accessor with a Supabase query when credentials
// are added; upgrade path is to replace `getX()` bodies with `supabase.from(x).select()`.
export const demoData = dataMode === "supabase" ? undefined : demo;
export const isDemo = dataMode === "demo";
