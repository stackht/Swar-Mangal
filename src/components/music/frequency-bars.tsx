"use client";

import * as React from "react";
import { motion, useReducedMotion } from "framer-motion";
import { cn } from "@/lib/utils/cn";

/**
 * Vertical frequency bars. Communicates "audio is playing / active".
 * Pure transform animation; freezes to a static profile when idle or reduced-motion.
 */
export function FrequencyBars({
  bars = 36,
  playing = false,
  className,
  color,
}: {
  bars?: number;
  playing?: boolean;
  className?: string;
  color?: string;
}) {
  const reduced = useReducedMotion();
  const heights = React.useMemo(
    () => Array.from({ length: bars }, (_, i) => 0.25 + 0.75 * Math.abs(Math.sin(i * 1.3) * Math.cos(i * 0.7 + 2))),
    [bars],
  );
  const animate = playing && !reduced;

  return (
    <div className={cn("flex h-full w-full items-center gap-[3px]", className)} role="presentation" aria-hidden>
      {heights.map((h, i) => (
        <motion.span
          key={i}
          className="flex-1 rounded-full"
          style={{ background: color ?? "currentColor", transformOrigin: "center" }}
          initial={{ scaleY: h }}
          animate={
            animate
              ? { scaleY: [h, 0.35 + (i % 4) * 0.16, h, 0.5 + (i % 3) * 0.18, h] }
              : { scaleY: h }
          }
          transition={
            animate
              ? { repeat: Infinity, duration: 1.1 + (i % 5) * 0.22, ease: "easeInOut", delay: (i % 7) * 0.05 }
              : { duration: 0.3 }
          }
        />
      ))}
    </div>
  );
}

/** Small inline waveform used inside list rows / cards. */
export function MiniWaveform({ className, playing = false }: { className?: string; playing?: boolean }) {
  return (
    <span className={cn("inline-block h-5 w-16", className)}>
      <FrequencyBars bars={18} playing={playing} />
    </span>
  );
}