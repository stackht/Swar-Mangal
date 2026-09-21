"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { CalendarDays } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useTimetable } from "@/lib/api/rpc-hooks";
import { useTokenAuth } from "@/lib/auth/token-auth";
import { fadeUp, listVariants } from "@/lib/motion";

const DAYS = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
const DAY_LABELS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

function fmt12(time: string) {
  if (!time) return "";
  const [h, m] = time.split(":").map(Number);
  const suffix = h >= 12 ? "PM" : "AM";
  const hour = h % 12 === 0 ? 12 : h % 12;
  return `${hour}:${String(m ?? 0).padStart(2, "0")} ${suffix}`;
}

export default function StaffTimetablePage() {
  const { session } = useTokenAuth();
  const branches = session?.branches ?? [];
  const [branch, setBranch] = React.useState(branches.length === 1 ? branches[0] : "ALL");
  const [selectedDay, setSelectedDay] = React.useState(() => (new Date().getDay() + 6) % 7);

  const timetable = useTimetable(branch);
  const entries = timetable.data?.entries ?? [];
  const sorted = [...entries].sort((a, b) => (a.startTime < b.startTime ? -1 : a.startTime > b.startTime ? 1 : 0));
  const dayEntries = sorted.filter((e) => e.dayOfWeek === selectedDay);
  const times = Array.from(new Set(sorted.map((e) => e.startTime))).sort();

  return (
    <motion.div initial="hidden" animate="visible" variants={listVariants} className="space-y-6">
      <motion.div variants={fadeUp} className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.16em] text-[#F7F2E8]/40">Staff · Academy</p>
          <h1 className="mt-1 text-2xl font-semibold tracking-tight text-[#F7F2E8]">Timetable</h1>
          <p className="mt-1 text-sm text-[#F7F2E8]/55">
            Recurring class slots {branch !== "ALL" ? `for ${branch}` : "across branches"}.
          </p>
        </div>
        {branches.length > 1 && (
          <select
            aria-label="Branch"
            value={branch}
            onChange={(e) => setBranch(e.target.value)}
            className="h-11 rounded-2xl border border-[#F7F2E8]/12 bg-[#0B0A10] px-3 text-sm text-[#F7F2E8] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D6A84F]/60"
          >
            <option value="ALL">All branches</option>
            {branches.map((b) => (
              <option key={b} value={b}>
                {b}
              </option>
            ))}
          </select>
        )}
      </motion.div>

      {timetable.isError ? (
        <motion.div variants={fadeUp}>
          <p className="rounded-2xl border border-red-400/30 bg-red-400/10 p-6 text-sm text-red-300">
            {timetable.error?.message?.replace(/\[.*\]$/, "") || "Could not load the timetable."}{" "}
            <button type="button" onClick={() => timetable.refetch()} className="font-medium text-[#D6A84F]">
              Retry
            </button>
          </p>
        </motion.div>
      ) : timetable.isPending ? (
        <div className="space-y-4">
          <Skeleton className="h-14 bg-white/[0.04]" />
          <Skeleton className="h-64 bg-white/[0.04]" />
        </div>
      ) : (
        <>
          <motion.div variants={fadeUp} className="grid grid-cols-7 gap-1 rounded-2xl border border-[#F7F2E8]/10 bg-white/[0.02] p-1">
            {DAYS.map((d, i) => {
              const active = i === selectedDay;
              const count = sorted.filter((e) => e.dayOfWeek === i).length;
              return (
                <button
                  key={d}
                  type="button"
                  onClick={() => setSelectedDay(i)}
                  aria-pressed={active}
                  className={`flex flex-col items-center gap-0.5 rounded-xl px-1 py-2 text-center transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D6A84F]/60 ${
                    active ? "bg-[#D6A84F]/15 text-[#D6A84F]" : "text-[#F7F2E8]/60 hover:bg-white/[0.04]"
                  }`}
                >
                  <span className="text-[11px] font-bold tracking-wide">{d}</span>
                  <span className={`text-[10px] ${count ? "text-[#F7F2E8]/50" : "text-[#F7F2E8]/25"}`}>
                    {count ? `${count}` : "—"}
                  </span>
                </button>
              );
            })}
          </motion.div>

          <motion.div variants={fadeUp} className="space-y-2">
            <h2 className="text-sm font-semibold text-[#F7F2E8]/80">{DAY_LABELS[selectedDay]}</h2>
            {dayEntries.length === 0 ? (
              <div className="flex flex-col items-center rounded-2xl border border-dashed border-[#F7F2E8]/15 bg-white/[0.02] px-6 py-14 text-center">
                <CalendarDays className="mb-3 h-8 w-8 text-[#F7F2E8]/25" aria-hidden />
                <p className="text-sm font-medium text-[#F7F2E8]/70">No classes on {DAY_LABELS[selectedDay]}</p>
                <p className="mt-1 text-xs text-[#F7F2E8]/40">Nothing scheduled here.</p>
              </div>
            ) : (
              dayEntries.map((entry) => (
                <div key={entry.id} className="flex items-center gap-4 rounded-2xl border border-[#F7F2E8]/10 bg-[#17131D] p-4">
                  <div className="min-w-[64px] text-center">
                    <p className="text-sm font-bold tabular-nums text-[#F7F2E8]">{fmt12(entry.startTime)}</p>
                    {entry.endTime && <p className="text-[10px] text-[#F7F2E8]/40">to {fmt12(entry.endTime)}</p>}
                  </div>
                  <div className="h-8 w-px bg-[#F7F2E8]/10" />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <p className="truncate text-sm font-semibold text-[#F7F2E8]">{entry.className}</p>
                      {entry.status !== "ENABLED" && (
                        <Badge variant="outline" className="border-[#F7F2E8]/20 text-[#F7F2E8]/50">
                          Disabled
                        </Badge>
                      )}
                    </div>
                    <p className="mt-0.5 text-xs text-[#F7F2E8]/50">
                      {[entry.teacherName || "No teacher assigned", entry.branch].filter(Boolean).join(" · ")}
                    </p>
                  </div>
                </div>
              ))
            )}
          </motion.div>

          {times.length > 0 && (
            <motion.div variants={fadeUp} className="overflow-x-auto rounded-2xl border border-[#F7F2E8]/10 bg-white/[0.02]">
              <div className="grid min-w-[880px]" style={{ gridTemplateColumns: "5rem repeat(7, minmax(0, 1fr))" }}>
                <div className="sticky left-0 z-10 border-b border-r border-[#F7F2E8]/10 bg-[#17131D] p-3 text-[10px] font-bold uppercase tracking-[0.14em] text-[#F7F2E8]/40" />
                {DAYS.map((d, i) => (
                  <div
                    key={d}
                    className="border-b border-l border-[#F7F2E8]/10 bg-[#17131D] p-2 text-center text-[11px] font-bold tracking-wide text-[#F7F2E8]/70"
                  >
                    {DAY_LABELS[i]}
                  </div>
                ))}
                {times.map((time) => (
                  <React.Fragment key={time}>
                    <div className="sticky left-0 z-10 flex items-start border-b border-r border-[#F7F2E8]/10 bg-[#17131D] p-3 text-xs font-semibold text-[#F7F2E8]/50">
                      {fmt12(time)}
                    </div>
                    {DAYS.map((_, i) => {
                      const cell = sorted.filter((e) => e.dayOfWeek === i && e.startTime === time);
                      return (
                        <div key={i} className="space-y-1 border-b border-l border-[#F7F2E8]/10 p-1.5">
                          {cell.map((entry) => (
                            <div
                              key={entry.id}
                              className="rounded-xl border border-[#D6A84F]/20 bg-[#D6A84F]/10 px-2 py-1.5"
                            >
                              <p className="truncate text-xs font-semibold text-[#F7F2E8]">{entry.className}</p>
                              <p className="truncate text-[10px] text-[#F7F2E8]/50">{entry.teacherName}</p>
                            </div>
                          ))}
                        </div>
                      );
                    })}
                  </React.Fragment>
                ))}
              </div>
            </motion.div>
          )}

          {entries.length === 0 && (
            <motion.div variants={fadeUp}>
              <Button
                variant="outline"
                onClick={() => timetable.refetch()}
                className="border-[#F7F2E8]/15 text-[#F7F2E8] hover:bg-white/[0.05]"
              >
                Refresh
              </Button>
            </motion.div>
          )}
        </>
      )}
    </motion.div>
  );
}
