"use client";

import * as React from "react";
import { motion, useReducedMotion } from "framer-motion";
import { Check, Pause, Play, RotateCcw, Square } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { MusicWave } from "@/components/music/music-wave";
import { cn } from "@/lib/utils/cn";
import { EASE } from "@/lib/motion";

function format(totalSeconds: number) {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

export function PracticeTimer({
  instrument,
  activity,
  onComplete,
}: {
  instrument: string;
  activity: string;
  onComplete?: (seconds: number) => void;
}) {
  const reduced = useReducedMotion();
  const [seconds, setSeconds] = React.useState(0);
  const [running, setRunning] = React.useState(false);
  const [done, setDone] = React.useState<number | null>(null);
  const intervalRef = React.useRef<ReturnType<typeof setInterval> | null>(null);

  React.useEffect(() => {
    if (running) {
      intervalRef.current = setInterval(() => setSeconds((s) => s + 1), 1000);
    } else if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [running]);

  const pause = () => setRunning(false);
  const start = () => setRunning(true);
  const reset = () => {
    setRunning(false);
    setSeconds(0);
  };
  const finish = () => {
    setRunning(false);
    const fin = seconds;
    setDone(fin);
    onComplete?.(fin);
    toast.success(`Logged ${Math.round(fin / 60)} min of ${activity}`);
  };

  const progress = seconds > 0 ? (Math.min(seconds, 3600) / 3600) * 100 : 0;
  const minutes = Math.round(seconds / 60);

  return (
    <div className="relative overflow-hidden rounded-3xl border border-border/60 bg-card p-6 sm:p-8">
      {done === null ? (
        <div className="flex flex-col items-center">
          <p className="text-caption text-muted-foreground">{instrument}</p>
          <p className="text-h2 mt-0.5">{activity}</p>

          <div className="relative mt-6 flex h-44 w-44 items-center justify-center">
            <svg width="176" height="176" className="-rotate-90">
              <circle cx="88" cy="88" r="76" fill="none" stroke="hsl(var(--secondary))" strokeWidth="8" />
              <motion.circle
                cx="88"
                cy="88"
                r="76"
                fill="none"
                stroke="url(#pt-gradient)"
                strokeWidth="8"
                strokeLinecap="round"
                strokeDasharray={2 * Math.PI * 76}
                animate={{ strokeDashoffset: 2 * Math.PI * 76 * (1 - progress / 100) }}
                transition={{ duration: 0.4, ease: EASE }}
              />
              <defs>
                <linearGradient id="pt-gradient" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="#8d6bf6" />
                  <stop offset="100%" stopColor="#52d69b" />
                </linearGradient>
              </defs>
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center gap-1.5">
              <motion.div
                key={`time-${seconds}`}
                initial={reduced ? false : { opacity: 0.4, scale: 0.97 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.2 }}
                className="text-4xl font-bold tabular-nums tracking-tight"
              >
                {format(seconds)}
              </motion.div>
              <div className={cn("h-8 w-36", !running && "opacity-20")}>
                <MusicWave bars={24} animate={running} height={32} className="text-lavender-500 dark:text-lavender-400 transition-opacity duration-300" ariaHidden />
              </div>
            </div>
          </div>

          <div className="mt-6 flex items-center gap-3">
            <Button variant="ghost" size="icon" aria-label="Reset" onClick={reset}>
              <RotateCcw className="h-4 w-4" />
            </Button>
            <Button
              size="lg"
              className={cn("h-14 w-14 rounded-full p-0 shadow-lift", running ? "bg-peach-500 text-white hover:bg-peach-600" : "bg-primary text-primary-foreground")}
              aria-label={running ? "Pause" : "Start"}
              onClick={running ? pause : start}
            >
              {running ? <Pause className="h-5 w-5" /> : <Play className="h-5 w-5 translate-x-0.5" />}
            </Button>
            <Button variant="ghost" size="icon" aria-label="Finish session" disabled={seconds === 0} onClick={finish}>
              <Square className="h-4 w-4" />
            </Button>
          </div>
        </div>
      ) : (
        <motion.div
          initial={reduced ? { opacity: 1 } : { opacity: 0, scale: 0.96 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.4, ease: EASE }}
          className="flex flex-col items-center py-6"
        >
          <motion.span
            initial={reduced ? false : { scale: 0.6, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ type: "spring", stiffness: 480, damping: 22, delay: 0.05 }}
            className="flex h-16 w-16 items-center justify-center rounded-full bg-mint-500 text-white shadow-lift"
            role="img"
            aria-label="Practice complete"
          >
            <Check className="h-7 w-7" strokeWidth={3} />
          </motion.span>
          <p className="text-h1 mt-5">Practice complete</p>
          <p className="mt-1 text-body-sm text-muted-foreground">
            {minutes} min{minutes === 1 ? "" : "s"} of {activity.toLowerCase()}
          </p>
          <p className="mt-4 flex items-center gap-1.5 rounded-full bg-peach-100/80 px-3 py-1 text-xs font-medium text-peach-700 dark:bg-peach-500/15 dark:text-peach-300">
            +1 day streak
          </p>
          <Button variant="outline" size="sm" className="mt-6" onClick={reset}>
            Start another session
          </Button>
        </motion.div>
      )}
    </div>
  );
}