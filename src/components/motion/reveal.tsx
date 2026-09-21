"use client";

import * as React from "react";
import { motion, useInView, useReducedMotion } from "framer-motion";

import { EASE } from "@/lib/motion";
import { cn } from "@/lib/utils/cn";

/** Fades content up once it scrolls into view. No-op under reduced motion. */
export function Reveal({
  children,
  className,
  delay = 0,
}: {
  children: React.ReactNode;
  className?: string;
  delay?: number;
}) {
  const ref = React.useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: "-64px 0px" });
  const reduced = useReducedMotion();

  return (
    <motion.div
      ref={ref}
      className={cn(className)}
      initial={reduced ? undefined : { opacity: 0, y: 26 }}
      animate={reduced || inView ? { opacity: 1, y: 0 } : { opacity: 0, y: 26 }}
      transition={{ duration: 0.7, ease: EASE, delay }}
    >
      {children}
    </motion.div>
  );
}