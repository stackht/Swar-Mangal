"use client";

import { motion, useReducedMotion } from "framer-motion";
import { cn } from "@/lib/utils/cn";

export function SegmentedControl<T extends string>({
  value,
  onChange,
  options,
  label,
  className,
}: {
  value: T;
  onChange: (v: T) => void;
  options: { value: T; label: string }[];
  label?: string;
  className?: string;
}) {
  const reduced = useReducedMotion();
  return (
    <div
      role="tablist"
      aria-label={label}
      className={cn("inline-flex items-center gap-0.5 rounded-xl bg-secondary p-1", className)}
    >
      {options.map((o) => {
        const active = o.value === value;
        return (
          <button
            key={o.value}
            role="tab"
            aria-selected={active}
            onClick={() => onChange(o.value)}
            className={cn(
              "relative rounded-lg px-3 py-1.5 text-[13px] font-medium transition-colors duration-200",
              active ? "text-foreground" : "text-muted-foreground hover:text-foreground",
            )}
          >
            {active && (
              <motion.span
                layoutId={`seg-${label ?? "control"}`}
                className="absolute inset-0 rounded-lg bg-background shadow-xs"
                transition={reduced ? { duration: 0 } : { type: "spring", stiffness: 420, damping: 34, mass: 0.6 }}
              />
            )}
            <span className="relative z-10">{o.label}</span>
          </button>
        );
      })}
    </div>
  );
}