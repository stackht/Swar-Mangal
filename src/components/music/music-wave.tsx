"use client";

import * as React from "react";
import { motion, useReducedMotion } from "framer-motion";
import { cn } from "@/lib/utils/cn";

export function MusicWave({
  bars = 20,
  animate = true,
  height = 100,
  className,
  ariaHidden = false,
}: {
  bars?: number;
  animate?: boolean;
  height?: number;
  className?: string;
  ariaHidden?: boolean;
}) {
  const reduced = useReducedMotion();
  const seed = React.useMemo(
    () => Array.from({ length: bars }, (_, i) => 0.32 + 0.68 * Math.abs(Math.sin(i * 1.7) * Math.cos(i * 0.9 + 1))),
    [bars],
  );
  const heights = React.useMemo(() => seed.map((s) => Math.max(12, s * 100)), [seed]);

  return (
    <svg
      viewBox={`0 0 ${bars * 4} ${height}`}
      preserveAspectRatio="none"
      className={cn("h-full w-full", className)}
      aria-hidden={ariaHidden}
      role="presentation"
    >
      {heights.map((h, i) => {
        const hh = Math.max(height * 0.12, (h / 100) * height);
        return (
          <motion.rect
            key={i}
            x={i * 4}
            y={(height - hh) / 2}
            width={Math.max(1.5, height * 0.022)}
            height={hh}
            rx={Math.max(0.75, height * 0.011)}
            initial={animate && !reduced ? { scaleY: 0.6, opacity: 0.5 } : { scaleY: 1, opacity: 1 }}
            animate={
              animate && !reduced
                ? {
                    scaleY: [0.6, 1, 0.55, 0.9, 0.6],
                    opacity: [0.5, 1, 0.45, 0.9, 0.5],
                  }
                : { scaleY: 1, opacity: 1 }
            }
            transition={
              reduced
                ? { duration: 0 }
                : {
                    repeat: Infinity,
                    duration: 1.6 + (i % 5) * 0.25,
                    ease: "easeInOut",
                    delay: (i % 7) * 0.08,
                  }
            }
            style={{ transformOrigin: "center", transformBox: "view-box" }}
          />
        );
      })}
    </svg>
  );
}