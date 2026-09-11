import * as React from "react";
import { motion, type HTMLMotionProps, useReducedMotion } from "framer-motion";
import { cn } from "@/lib/utils/cn";
import { MusicWave } from "@/components/music/music-wave";
import { EASE } from "@/lib/motion";

type Gradient = "navy" | "lavender" | "mint" | "peach" | "sky" | "none";

const gradientMap: Record<Gradient, string> = {
  navy: "from-navy-950 via-navy-900 to-navy-800 text-white",
  lavender: "from-lavender-600/95 via-lavender-500 to-mint-500 text-white",
  mint: "from-mint-600/95 via-mint-500 to-lavender-500 text-white",
  peach: "from-peach-600/95 via-peach-500 to-lavender-500 text-white",
  sky: "from-sky-600/95 via-sky-500 to-mint-500 text-white",
  none: "bg-card text-card-foreground",
};

export interface GradientCardProps
  extends Omit<React.HTMLAttributes<HTMLDivElement>, "onDrag" | "onDragStart" | "onDragEnd" | "onAnimationStart"> {
  gradient?: Gradient;
  children: React.ReactNode;
  hover?: boolean;
  index?: number;
  delay?: number;
  wave?: boolean;
}

export function GradientCard({
  gradient = "lavender",
  children,
  className,
  hover = true,
  index = 0,
  delay = 0,
  wave = true,
  ...props
}: GradientCardProps) {
  const reduced = useReducedMotion();
  return (
    <motion.div
      initial={{ opacity: 0, y: reduced ? 0 : 16 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-40px" }}
      transition={{ duration: 0.45, delay: delay + index * 0.05, ease: EASE }}
      whileHover={hover && !reduced ? { y: -3 } : undefined}
      className={cn(
        "relative overflow-hidden rounded-3xl bg-gradient-to-br shadow-soft dark:shadow-soft",
        gradientMap[gradient],
        className,
      )}
      {...(props as HTMLMotionProps<"div">)}
    >
      {wave && gradient !== "none" && (
        <MusicWave
          className="pointer-events-none absolute -right-6 bottom-0 h-full w-1/2 text-white/[0.12] dark:text-white/10"
          bars={26}
          animate={false}
          aria-hidden
        />
      )}
      {children}
    </motion.div>
  );
}