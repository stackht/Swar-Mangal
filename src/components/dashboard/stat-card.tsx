"use client";

import { motion } from "framer-motion";
import { ArrowDownRight, ArrowUpRight } from "lucide-react";

import { cn } from "@/lib/utils/cn";
import { EASE, surfaceHover } from "@/lib/motion";
import type { LucideIcon } from "lucide-react";

export interface StatCardProps {
  label: string;
  value: string | number;
  icon: LucideIcon;
  delta?: number;
  hint?: string;
  accent?: "lavender" | "mint" | "peach" | "sky";
  delay?: number;
}

const accentMap: Record<NonNullable<StatCardProps["accent"]>, string> = {
  lavender: "bg-lavender-100/70 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300",
  mint: "bg-mint-100/70 text-mint-700 dark:bg-mint-500/15 dark:text-mint-300",
  peach: "bg-peach-100/70 text-peach-700 dark:bg-peach-500/15 dark:text-peach-300",
  sky: "bg-sky-100/70 text-sky-700 dark:bg-sky-500/15 dark:text-sky-300",
};

/** Compact premium stat. Title is above the value — reads like a label, not a header. */
export function StatCard({ label, value, icon: Icon, delta, hint, accent = "lavender", delay = 0 }: StatCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45, delay, ease: EASE }}
      whileHover={surfaceHover}
      className="group rounded-2xl border border-border/60 bg-card p-4 transition-[box-shadow,transform] duration-200 ease-ease-out-expo hover:shadow-soft"
    >
      <div className="flex items-center justify-between">
        <span className="text-caption text-muted-foreground">{label}</span>
        <span className={cn("flex h-8 w-8 items-center justify-center rounded-lg transition-transform duration-200 group-hover:scale-105", accentMap[accent])}>
          <Icon className="h-4 w-4" />
        </span>
      </div>
      <div className="mt-2 flex items-baseline gap-2">
        <p className="text-h1 text-[22px] leading-none">{value}</p>
        {typeof delta === "number" && (
          <span
            className={cn(
              "flex items-center gap-0.5 text-xs font-medium",
              delta >= 0 ? "text-mint-600 dark:text-mint-300" : "text-peach-600 dark:text-peach-300",
            )}
          >
            {delta >= 0 ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
            {Math.abs(delta)}%
          </span>
        )}
      </div>
      {hint && <p className="mt-1 text-xs text-muted-foreground/70">{hint}</p>}
    </motion.div>
  );
}