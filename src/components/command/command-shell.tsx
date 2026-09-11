"use client";

import { CommandPalette, CommandPaletteProvider } from "@/components/command/command-palette";

/** Wraps children in command palette provider and mounts the palette. */
export function CommandShell({ children }: { children: React.ReactNode }) {
  return (
    <CommandPaletteProvider>
      {children}
      <CommandPalette />
    </CommandPaletteProvider>
  );
}