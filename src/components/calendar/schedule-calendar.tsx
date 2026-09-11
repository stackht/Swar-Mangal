"use client";

import * as React from "react";
import { motion, useReducedMotion } from "framer-motion";
import {
  addDays,
  addWeeks,
  differenceInMinutes,
  format,
  isSameDay,
  startOfWeek,
} from "date-fns";
import { AlertTriangle, ChevronLeft, ChevronRight, MapPin, Video } from "lucide-react";

import { SegmentedControl } from "@/components/ui/segmented-control";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Avatar } from "@/components/ui/avatar";
import { cn } from "@/lib/utils/cn";
import { formatTime } from "@/lib/utils/cn";
import { instrumentIcon } from "@/lib/music-icons";
import { EASE } from "@/lib/motion";
import type { ClassEvent } from "@/types";

type Mode = "day" | "week" | "agenda";

const HOUR_PX = 92;
const DAY_START_H = 8;
const DAY_END_H = 20;

function hexA(hex: string, alpha: number) {
  const h = hex.replace("#", "");
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

const dateKey = (d: Date) => d.toDateString();

export function ScheduleCalendar({
  classes,
  admin = false,
  className,
}: {
  classes: ClassEvent[];
  admin?: boolean;
  className?: string;
}) {
  const reduced = useReducedMotion();
  const [mode, setMode] = React.useState<Mode>("week");
  const [anchor, setAnchor] = React.useState<Date>(new Date());
  const [now, setNow] = React.useState(new Date());
  const [selected, setSelected] = React.useState<ClassEvent | null>(null);

  React.useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(t);
  }, []);

  const weekStart = startOfWeek(anchor, { weekStartsOn: 1 });
  const weekDays = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  const byDay = React.useMemo(() => {
    const map: Record<string, ClassEvent[]> = {};
    classes.forEach((c) => {
      const k = dateKey(new Date(c.start_time));
      (map[k] ??= []).push(c);
    });
    return map;
  }, [classes]);

  const conflictsFor = (day: Date) => {
    const items = (byDay[dateKey(day)] ?? []).sort((a, b) => +new Date(a.start_time) - +new Date(b.start_time));
    const busy: string[] = [];
    for (let i = 0; i < items.length; i++) {
      for (let j = i + 1; j < items.length; j++) {
        if (new Date(items[i].start_time) < new Date(items[j].end_time) && new Date(items[j].start_time) < new Date(items[i].end_time)) {
          busy.push(items[i].id, items[j].id);
        }
      }
    }
    return new Set(busy);
  };

  const nowInRange =
    now.getHours() >= DAY_START_H && now.getHours() < DAY_END_H;

  const go = (dir: number) => {
    if (mode === "day") setAnchor((a) => addDays(a, dir));
    else setAnchor((a) => addWeeks(a, dir));
  };

  const rangeLabel =
    mode === "day"
      ? format(anchor, "EEEE, MMMM d")
      : `${format(weekStart, "MMM d")} – ${format(addDays(weekStart, 6), "MMM d")}`;

  const nowTop = ((now.getHours() - DAY_START_H) * 60 + now.getMinutes()) * (HOUR_PX / 60);

  const renderBlock = (c: ClassEvent, startMin: number, extra: React.CSSProperties) => {
    const durMin = differenceInMinutes(new Date(c.end_time), new Date(c.start_time));
    return (
      <button
        key={c.id}
        onClick={() => setSelected(c)}
        className="group absolute left-1 right-1 overflow-hidden rounded-xl border-l-[3px] px-2 py-1 text-left transition-[transform,box-shadow] duration-200 hover:z-20 hover:shadow-soft"
        style={{
          top: (startMin - DAY_START_H * 60) * (HOUR_PX / 60),
          height: Math.max(26, durMin * (HOUR_PX / 60)),
          background: hexA(c.color, 0.14),
          borderLeftColor: c.color,
          ...extra,
        }}
      >
        <p className="truncate text-[13px] font-semibold leading-tight">{c.title}</p>
        <p className="text-[11px] opacity-70">{formatTime(c.start_time)}</p>
      </button>
    );
  };

  const hours = Array.from({ length: DAY_END_H - DAY_START_H }, (_, i) => DAY_START_H + i);

  return (
    <div className={cn("space-y-4", className)}>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-1.5">
          <Button variant="ghost" size="icon" aria-label="Previous" onClick={() => go(-1)}>
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <span className="min-w-36 px-1 text-center text-sm font-semibold tracking-tight">{rangeLabel}</span>
          <Button variant="ghost" size="icon" aria-label="Next" onClick={() => go(1)}>
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant={isSameDay(anchor, now) ? "secondary" : "outline"}
            size="sm"
            onClick={() => {
              setAnchor(new Date());
              setMode("day");
            }}
          >
            Today
          </Button>
          <SegmentedControl<Mode>
            label="Calendar view"
            value={mode}
            onChange={setMode}
            options={[
              { value: "day", label: "Day" },
              { value: "week", label: "Week" },
              { value: "agenda", label: "Agenda" },
            ]}
          />
        </div>
      </div>

      {mode === "day" && (
        <div className="font-sans">
          <div className="grid h-auto grid-cols-[52px_1fr] rounded-2xl border border-border/60 bg-card">
            <div className="relative" style={{ height: hours.length * HOUR_PX + 36 }}>
              {hours.map((h) => (
                <div key={h} className="absolute right-2 -translate-y-1/2 text-[11px] tabular-nums text-muted-foreground" style={{ top: (h - DAY_START_H) * HOUR_PX }}>
                  {format(new Date().setHours(h, 0), "ha")}
                </div>
              ))}
            </div>
            <div className="relative border-l border-border/60" style={{ height: hours.length * HOUR_PX + 36 }}>
              {hours.map((h) => (
                <div key={h} className="absolute inset-x-0 border-t border-border/40" style={{ top: h * HOUR_PX - DAY_START_H * HOUR_PX }} />
              ))}
              {isSameDay(anchor, now) && nowInRange && (
                <div className="absolute inset-x-0 z-10" style={{ top: nowTop }}>
                  <div className="h-0.5 rounded-full bg-peach-500" />
                  <span className="absolute -left-1 -top-[5px] h-2.5 w-2.5 rounded-full bg-peach-500 ring-2 ring-background" />
                </div>
              )}
              {(byDay[dateKey(anchor)] ?? []).map((c) =>
                renderBlock(c, new Date(c.start_time).getHours() * 60 + new Date(c.start_time).getMinutes(), {}),
              )}
              {!(byDay[dateKey(anchor)] ?? []).length && (
                <p className="absolute inset-x-0 top-8 text-center text-sm text-muted-foreground">No classes</p>
              )}
            </div>
          </div>
        </div>
      )}

      {mode === "week" && (
        <>
          {/* Desktop grid */}
          <motion.div
            key="week-grid"
            initial={reduced ? false : { opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, ease: EASE }}
            className="hidden lg:block"
          >
            <div className="overflow-hidden rounded-2xl border border-border/60 bg-card">
              <div className="grid grid-cols-[52px_repeat(7,1fr)] border-b border-border/60">
                <div />
                {weekDays.map((d) => {
                  const isToday = isSameDay(d, now);
                  const conflicts = conflictsFor(d);
                  return (
                    <div key={d.getTime()} className={cn("flex flex-col items-center gap-0.5 py-2.5", isToday && "bg-lavender-100/50 dark:bg-lavender-500/10")}>
                      <span className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">{format(d, "EEE")}</span>
                      <span className={cn("flex h-7 w-7 items-center justify-center rounded-full text-sm font-semibold", isToday && "bg-lavender-500 text-white")}>
                        {format(d, "d")}
                      </span>
                      {conflicts.size > 0 && (
                        <span className="mt-0.5 flex items-center gap-0.5 rounded-full bg-peach-100 px-1.5 py-px text-[9px] font-medium text-peach-700 dark:bg-peach-500/15 dark:text-peach-300">
                          <AlertTriangle className="h-2.5 w-2.5" /> conflict
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>
              <div className="grid grid-cols-[52px_repeat(7,1fr)]">
                <div className="relative" style={{ height: hours.length * HOUR_PX + 28 }}>
                  {hours.map((h) => (
                    <div key={h} className="absolute right-2 -translate-y-1/2 text-[11px] tabular-nums text-muted-foreground" style={{ top: (h - DAY_START_H) * HOUR_PX }}>
                      {format(new Date().setHours(h, 0), "ha")}
                    </div>
                  ))}
                </div>
                {weekDays.map((d) => {
                  const isToday = isSameDay(d, now);
                  const dayClasses = byDay[dateKey(d)] ?? [];
                  const conflicts = conflictsFor(d);
                  return (
                    <div key={d.getTime()} className="relative border-l border-border/40 last:border-r-0" style={{ height: hours.length * HOUR_PX + 28 }}>
                      {hours.map((h) => (
                        <div key={h} className="absolute inset-x-0 border-t border-border/40" style={{ top: h * HOUR_PX - DAY_START_H * HOUR_PX }} />
                      ))}
                      {isToday && nowInRange && (
                        <div className="absolute inset-x-0 z-10" style={{ top: nowTop }}>
                          <div className="h-0.5 rounded-full bg-peach-500" />
                        </div>
                      )}
                      {dayClasses.map((c) =>
                        renderBlock(
                          c,
                          new Date(c.start_time).getHours() * 60 + new Date(c.start_time).getMinutes(),
                          conflicts.has(c.id) ? { zIndex: 15, outline: `1.5px solid ${hexA(c.color, 0.4)}` } : {},
                        ),
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </motion.div>

          {/* Mobile: day-by-day agenda */}
          <motion.div
            key="week-mobile"
            initial={reduced ? false : { opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, ease: EASE }}
            className="space-y-4 lg:hidden"
          >
            {weekDays.map((d) => {
              const dayClasses = (byDay[dateKey(d)] ?? []).sort((a, b) => +new Date(a.start_time) - +new Date(b.start_time));
              const isToday = isSameDay(d, now);
              return (
                <div key={d.getTime()} className="rounded-2xl border border-border/60 bg-card">
                  <div className={cn("flex items-center justify-between border-b border-border/50 px-4 py-2.5", isToday && "bg-lavender-100/40 dark:bg-lavender-500/10")}>
                    <p className="text-[13px] font-semibold">
                      {format(d, "EEEE, MMM d")}
                      {isToday && <span className="ml-2 rounded-full bg-lavender-500 px-2 py-0.5 text-[10px] font-semibold text-white">Today</span>}
                    </p>
                    {conflictsFor(d).size > 0 && (
                      <Badge variant="peach"><AlertTriangle className="h-3 w-3" /> conflict</Badge>
                    )}
                  </div>
                  {dayClasses.length === 0 ? (
                    <p className="px-4 py-4 text-sm text-muted-foreground">No classes</p>
                  ) : (
                    <div className="divide-y divide-border/50">
                      {dayClasses.map((c) => {
                        const Icon = instrumentIcon(c.instrument);
                        return (
                          <button key={c.id} onClick={() => setSelected(c)} className="flex w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-secondary/60">
                            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl" style={{ backgroundColor: hexA(c.color, 0.14), color: c.color }}>
                              <Icon className="h-4 w-4" />
                            </span>
                            <div className="min-w-0 flex-1">
                              <p className="truncate text-sm font-medium">{c.title}</p>
                              <p className="text-xs text-muted-foreground">{formatTime(c.start_time)} · {c.teacher_name}</p>
                            </div>
                            <span className="text-xs text-muted-foreground">{c.room ?? c.mode}</span>
                          </button>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            })}
          </motion.div>
        </>
      )}

      {mode === "agenda" && (
        <motion.div
          key={mode}
          initial={reduced ? false : { opacity: 0, y: 6 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3, ease: EASE }}
          className="space-y-4"
        >
          {weekDays.map((d) => {
            const dayClasses = (byDay[dateKey(d)] ?? []).sort((a, b) => +new Date(a.start_time) - +new Date(b.start_time));
            const isToday = isSameDay(d, now);
            if (dayClasses.length === 0) return null;
            return (
              <div key={d.getTime()} className="rounded-2xl border border-border/60 bg-card">
                <div className={cn("flex items-center justify-between border-b border-border/50 px-4 py-2.5", isToday && "bg-lavender-100/40 dark:bg-lavender-500/10")}>
                  <p className="text-[13px] font-semibold">
                    {format(d, "EEEE, MMM d")}
                    {isToday && <span className="ml-2 rounded-full bg-lavender-500 px-2 py-0.5 text-[10px] font-semibold text-white">Today</span>}
                  </p>
                  <span className="text-xs text-muted-foreground">{dayClasses.length} class{dayClasses.length > 1 ? "es" : ""}</span>
                </div>
                <div className="divide-y divide-border/50">
                  {dayClasses.map((c) => (
                    <button key={c.id} onClick={() => setSelected(c)} className="flex w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-secondary/60">
                      <span className="w-14 shrink-0 text-sm font-semibold tabular-nums">{formatTime(c.start_time)}</span>
                      <span className="h-8 w-1 shrink-0 rounded-full" style={{ backgroundColor: c.color }} />
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-medium">{c.title}</p>
                        <p className="text-xs text-muted-foreground">{c.teacher_name} · {c.student_ids.length} student{c.student_ids.length !== 1 ? "s" : ""}</p>
                      </div>
                      <span className="flex shrink-0 items-center gap-1 text-xs text-muted-foreground">
                        {c.mode === "online" ? <Video className="h-3.5 w-3.5" /> : <MapPin className="h-3.5 w-3.5" />}
                        {c.room ?? c.mode}
                      </span>
                    </button>
                  ))}
                </div>
              </div>
            );
          })}
          {weekDays.every((d) => (byDay[dateKey(d)] ?? []).length === 0) && (
            <p className="py-10 text-center text-sm text-muted-foreground">Nothing scheduled for this week.</p>
          )}
        </motion.div>
      )}

      <Dialog open={!!selected} onOpenChange={(o) => !o && setSelected(null)}>
        {selected && (
          <DialogContent className="max-w-sm">
            <DialogHeader>
              <span className="flex h-10 w-10 items-center justify-center rounded-xl" style={{ backgroundColor: hexA(selected.color, 0.14), color: selected.color }}>
                {(() => { const I = instrumentIcon(selected.instrument); return <I className="h-5 w-5" />; })()}
              </span>
              <DialogTitle className="mt-2">{selected.title}</DialogTitle>
              <DialogDescription>
                {format(new Date(selected.start_time), "EEEE, MMMM d")} · {formatTime(selected.start_time)} – {formatTime(selected.end_time)}
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-3 text-sm">
              <div className="flex items-center gap-3">
                <Avatar name={selected.teacher_name} size="sm" />
                <div>
                  <p className="font-medium">{selected.teacher_name}</p>
                  <p className="text-xs text-muted-foreground">Teacher · {selected.instrument}</p>
                </div>
              </div>
              <div className="flex items-center gap-2 text-muted-foreground">
                <Badge variant={selected.mode === "online" ? "mint" : "lavender"}>{selected.mode}</Badge>
                <span className="text-xs">{selected.room ?? "Online"} · {selected.duration_min} min · {selected.student_ids.length} student{selected.student_ids.length !== 1 ? "s" : ""}</span>
              </div>
              {admin && (
                <div className="flex gap-2 pt-1">
                  <Button size="sm" variant="outline" className="flex-1">Reschedule</Button>
                  <Button size="sm" variant="outline" className="flex-1 text-peach-600 dark:text-peach-300">Cancel class</Button>
                </div>
              )}
            </div>
          </DialogContent>
        )}
      </Dialog>
    </div>
  );
}