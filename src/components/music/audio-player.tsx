"use client";

import * as React from "react";
import { Pause, Play, Volume2, VolumeX } from "lucide-react";
import { toast } from "sonner";

import { FrequencyBars } from "@/components/music/frequency-bars";
import { cn } from "@/lib/utils/cn";

function fmt(s: number) {
  if (!isFinite(s)) return "0:00";
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60);
  return `${m}:${sec.toString().padStart(2, "0")}`;
}

const SPEEDS = [0.5, 0.75, 1, 1.25, 1.5];

export function AudioPlayer({
  src,
  title,
  subtitle,
  className,
}: {
  src: string;
  title?: string;
  subtitle?: string;
  className?: string;
}) {
  const audioRef = React.useRef<HTMLAudioElement | null>(null);
  const [playing, setPlaying] = React.useState(false);
  const [ready, setReady] = React.useState(false);
  const [error, setError] = React.useState(false);
  const [t, setT] = React.useState(0);
  const [dur, setDur] = React.useState(0);
  const [speed, setSpeed] = React.useState(1);
  const [speedIdx, setSpeedIdx] = React.useState(2);
  const [volume, setVolume] = React.useState(1);
  const scrubRef = React.useRef(false);

  React.useEffect(() => {
    const a = new Audio(src);
    audioRef.current = a;
    a.preload = "metadata";
    const onTime = () => { if (!scrubRef.current) setT(a.currentTime); };
    const onMeta = () => { setReady(true); setDur(a.duration); };
    const onEnd = () => setPlaying(false);
    const onErr = () => { setError(true); toast.error("Audio preview unavailable"); };
    a.addEventListener("timeupdate", onTime);
    a.addEventListener("loadedmetadata", onMeta);
    a.addEventListener("ended", onEnd);
    a.addEventListener("error", onErr);
    return () => {
      a.removeEventListener("timeupdate", onTime);
      a.removeEventListener("loadedmetadata", onMeta);
      a.removeEventListener("ended", onEnd);
      a.removeEventListener("error", onErr);
      a.pause();
      a.src = "";
    };
  }, [src]);

  const a = audioRef.current;

  React.useEffect(() => {
    if (!a) return;
    a.playbackRate = speed;
  }, [a, speed]);

  const toggle = () => {
    if (!a) return;
    if (a.paused) { a.play(); setPlaying(true); }
    else { a.pause(); setPlaying(false); }
  };

  const seek = (pct: number) => {
    if (!a) return;
    const t = pct * dur;
    a.currentTime = t;
    setT(t);
  };

  const cycleSpeed = () => {
    const next = (speedIdx + 1) % SPEEDS.length;
    setSpeedIdx(next);
    setSpeed(SPEEDS[next]);
  };

  const toggleMute = () => {
    if (!a) return;
    a.muted = !a.muted;
    setVolume(a.muted ? 0 : 1);
  };

  const scrub = (e: React.PointerEvent) => {
    if (!scrubRef.current || !dur) return;
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const pct = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
    seek(pct);
  };

  const onPointerDown = (e: React.PointerEvent) => {
    scrubRef.current = true;
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    scrub(e);
  };

  const onPointerUp = () => { scrubRef.current = false; };

  const pct = dur > 0 ? (t / dur) * 100 : 0;

  return (
    <div className={cn("rounded-2xl border border-border/60 bg-card p-4", className)}>
      <div className="flex items-center gap-3">
        <button
          onClick={toggle}
          disabled={error}
          aria-label={playing ? "Pause" : "Play"}
          className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-soft transition-[transform,box-shadow] duration-200 hover:shadow-lift active:scale-95 disabled:opacity-50"
        >
          {playing ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4 translate-x-0.5" />}
        </button>
        <div className="min-w-0 flex-1">
          {title && <p className="truncate text-[13px] font-semibold">{title}</p>}
          {subtitle && <p className="truncate text-[11px] text-muted-foreground">{subtitle}</p>}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={toggleMute}
            className="rounded-lg p-1.5 text-muted-foreground transition-colors hover:bg-secondary hover:text-foreground"
            aria-label={volume === 0 ? "Unmute" : "Mute"}
          >
            {volume === 0 ? <VolumeX className="h-4 w-4" /> : <Volume2 className="h-4 w-4" />}
          </button>
          <button
            onClick={cycleSpeed}
            className="min-w-[32px] rounded-lg bg-secondary px-1.5 py-1 text-[11px] font-semibold text-muted-foreground transition-colors hover:text-foreground"
          >
            {speed}×
          </button>
        </div>
      </div>

      {/* Waveform */}
      <div className="mt-3 h-7 opacity-60">
        <FrequencyBars bars={48} playing={playing && ready} />
      </div>

      {/* Progress scrub */}
      <div
        role="slider"
        aria-label="Seek"
        aria-valuemin={0}
        aria-valuemax={Math.round(dur)}
        aria-valuenow={Math.round(t)}
        tabIndex={0}
        onPointerDown={onPointerDown}
        onPointerMove={scrub}
        onPointerUp={onPointerUp}
        onKeyDown={(e) => {
          if (e.key === "ArrowRight" && a) seek(Math.min(1, (t + 5) / dur));
          if (e.key === "ArrowLeft" && a) seek(Math.max(0, (t - 5) / dur));
          if (e.key === " ") { e.preventDefault(); toggle(); }
        }}
        className="group relative mt-2 h-2 cursor-pointer rounded-full bg-secondary outline-none focus-visible:outline-2 focus-visible:outline-ring"
      >
        <span
          className="absolute inset-y-0 left-0 rounded-full bg-primary transition-all duration-100"
          style={{ width: `${pct}%` }}
        />
        <span
          className="absolute left-0 top-1/2 h-3.5 w-3.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary shadow-sm opacity-0 transition-opacity group-hover:opacity-100 group-active:opacity-100"
          style={{ left: `${pct}%` }}
        />
      </div>

      <div className="mt-1 flex justify-between text-[10px] tabular-nums text-muted-foreground">
        <span>{fmt(t)}</span>
        <span>{fmt(dur)}</span>
      </div>
    </div>
  );
}