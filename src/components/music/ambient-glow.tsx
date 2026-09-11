"use client";

import { cn } from "@/lib/utils/cn";

/**
 * Subtle ambient gradient glow behind content.
 * Use sparingly behind hero sections only.
 */
export function AmbientGlow({
  color1 = "hsl(262 80% 60% / 0.15)",
  color2 = "hsl(320 60% 50% / 0.10)",
  className,
}: {
  color1?: string;
  color2?: string;
  className?: string;
}) {
  return (
    <div className={cn("pointer-events-none absolute -inset-x-20 -top-32 h-80 overflow-hidden opacity-60", className)} aria-hidden>
      <div
        className="absolute left-1/4 top-0 h-72 w-72 rounded-full blur-3xl"
        style={{ background: color1 }}
      />
      <div
        className="absolute right-1/4 top-10 h-64 w-64 rounded-full blur-3xl"
        style={{ background: color2 }}
      />
    </div>
  );
}