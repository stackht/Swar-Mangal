"use client";

import * as React from "react";

/**
 * Horizontal scroll container for content rails.
 * Provides scroll snap, padding, and fade edges on desktop.
 */
export function MusicRail({
  children,
  className,
  label,
}: {
  children: React.ReactNode;
  className?: string;
  label?: string;
}) {
  return (
    <div className={className}>
      {label && (
        <h3 className="mb-3 text-base font-semibold tracking-tight">{label}</h3>
      )}
      <div className="relative">
        <div
          className="flex gap-3 overflow-x-auto scroll-smooth snap-x snap-mandatory pb-2 no-scrollbar sm:gap-4 sm:pb-3"
        >
          {children}
        </div>
      </div>
    </div>
  );
}