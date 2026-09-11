"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/utils/cn";

export interface ProgressRingProps {
  value: number;
  size?: number;
  stroke?: number;
  color?: string;
  trackColor?: string;
  label?: string;
  sublabel?: string;
  className?: string;
}

export function ProgressRing({
  value,
  size = 96,
  stroke = 10,
  color = "var(--primary)",
  trackColor = "hsl(var(--secondary))",
  label,
  sublabel,
  className,
}: ProgressRingProps) {
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const clamped = Math.max(0, Math.min(100, value));

  return (
    <div className={cn("relative inline-flex items-center justify-center", className)} style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={trackColor}
          strokeWidth={stroke}
        />
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={circumference}
          initial={{ strokeDashoffset: circumference }}
          animate={{ strokeDashoffset: circumference - (clamped / 100) * circumference }}
          transition={{ duration: 1, ease: [0.22, 1, 0.36, 1] }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
        {label !== undefined ? (
          <>
            <span className="text-xl font-bold leading-none">{label}</span>
            {sublabel && <span className="mt-0.5 text-[10px] text-muted-foreground">{sublabel}</span>}
          </>
        ) : (
          <span className="text-xl font-bold leading-none">{Math.round(clamped)}%</span>
        )}
      </div>
    </div>
  );
}
