"use client";

import * as React from "react";
import { motion, useReducedMotion } from "framer-motion";
import { cn } from "@/lib/utils/cn";

/**
 * Artwork-driven visual card. Uses gradient backgrounds to simulate album/course artwork.
 * Supports dark overlay, hover scale, and optional play button.
 */
export function MusicArtwork({
  gradient,
  label,
  sublabel,
  icon,
  className,
  onClick,
  playLabel,
  aspect = "aspect-square",
}: {
  gradient: string;
  label: string;
  sublabel?: string;
  icon?: React.ReactNode;
  className?: string;
  onClick?: () => void;
  playLabel?: string;
  aspect?: string;
}) {
  const reduced = useReducedMotion();
  return (
    <motion.button
      onClick={onClick}
      whileHover={reduced ? undefined : { y: -4, scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      className={cn(
        "group relative overflow-hidden rounded-2xl sm:rounded-3xl text-left transition-shadow duration-300 hover:shadow-lift focus-visible:outline-2 focus-visible:outline-ring",
        aspect,
        className,
      )}
    >
      {/* Artwork background */}
      <div
        className={cn("absolute inset-0 bg-gradient-to-br", gradient)}
        aria-hidden
      />
      {/* Subtle pattern overlay */}
      <div className="absolute inset-0 opacity-[0.08]" style={{
        backgroundImage: "url(\"data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E\")",
      }} />
      {/* Bottom gradient for text */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />

      {/* Content */}
      <div className="absolute inset-0 flex flex-col justify-end p-4 sm:p-5">
        <div className="flex items-end justify-between gap-3">
          <div className="min-w-0">
            <p className="text-sm font-bold text-white leading-tight sm:text-base">{label}</p>
            {sublabel && <p className="mt-0.5 text-xs text-white/70">{sublabel}</p>}
          </div>
          {icon && (
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/15 text-white transition-transform group-hover:scale-110">
              {icon}
            </span>
          )}
          {playLabel && (
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-white text-violet-700 shadow-lg transition-transform group-hover:scale-110">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z" /></svg>
            </span>
          )}
        </div>
      </div>
    </motion.button>
  );
}