"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { ArrowRight, Command as CommandIcon } from "lucide-react";
import { useTheme } from "next-themes";

import { useAuth } from "@/components/auth/auth-provider";
import { navByRole } from "@/lib/config/navigation";

const CommandCtx = React.createContext<{ isOpen: boolean; open: (v: boolean) => void } | undefined>(undefined);
export function useCommandPalette() {
  return React.useContext(CommandCtx) ?? { isOpen: false, open: () => {} };
}

export function CommandPaletteProvider({ children }: { children: React.ReactNode }) {
  const [isOpen, setOpen] = React.useState(false);
  React.useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setOpen((v) => !v);
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);
  return (
    <CommandCtx.Provider value={{ isOpen, open: setOpen }}>
      {children}
    </CommandCtx.Provider>
  );
}

const EASE = [0.22, 1, 0.36, 1] as const;

export function CommandPalette() {
  const { isOpen, open: setOpen } = useCommandPalette();
  const { role, logout } = useAuth();
  const router = useRouter();
  const { theme, setTheme } = useTheme();
  const [query, setQuery] = React.useState("");
  const inputRef = React.useRef<HTMLInputElement>(null);

  React.useEffect(() => {
    if (isOpen) setQuery("");
  }, [isOpen]);

  React.useEffect(() => {
    if (isOpen) inputRef.current?.focus();
  }, [isOpen]);

  const sections = React.useMemo(() => {
    const items: { group: string; items: { label: string; action: () => void }[] }[] = [];

    const nav = role ? navByRole[role] ?? [] : [];
    const cmds: { label: string; action: () => void }[] = [];
    for (const sec of nav) {
      for (const item of sec.items) {
        cmds.push({ label: item.title, action: () => { router.push(item.href); setOpen(false); } });
      }
    }
    items.push({ group: "Navigate", items: cmds });
    items.push({
      group: "Actions",
      items: [
        { label: `Switch to ${theme === "dark" ? "light" : "dark"} mode`, action: () => { setTheme(theme === "dark" ? "light" : "dark"); setOpen(false); } },
        { label: "Log out", action: () => { logout(); setOpen(false); } },
      ],
    });
    return items;
  }, [role, router, theme, setTheme, logout, setOpen]);

  const results = React.useMemo(() => {
    if (!query) return sections;
    return sections
      .map((s) => ({
        ...s,
        items: s.items.filter((i) => i.label.toLowerCase().includes(query.toLowerCase())),
      }))
      .filter((s) => s.items.length > 0);
  }, [query, sections]);

  const flatResults = React.useMemo(() => results.flatMap((s) => s.items), [results]);

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === "Escape") { setOpen(false); return; }
    if (e.key === "Enter" && flatResults.length > 0) { flatResults[0].action(); }
  };

  return (
    <DialogShell open={isOpen} onOpenChange={setOpen}>
      <motion.div
        initial={false}
        animate={isOpen ? { opacity: 1, scale: 1 } : { opacity: 0, scale: 0.97 }}
        transition={{ duration: 0.2, ease: EASE }}
        className="w-full max-w-lg origin-center overflow-hidden rounded-2xl border border-border/70 bg-card shadow-float"
        role="dialog"
        aria-label="Command palette"
      >
        <div className="flex items-center gap-3 border-b border-border/60 px-4 py-3">
          <CommandIcon className="h-4 w-4 text-muted-foreground" />
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={onKey}
            placeholder="Type a command…"
            className="flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground"
            aria-label="Command"
          />
          <kbd className="rounded-lg border border-border bg-secondary px-1.5 py-0.5 text-[10px] font-semibold text-muted-foreground">ESC</kbd>
        </div>
        <div className="max-h-72 overflow-y-auto p-2">
          {results.length === 0 && (
            <p className="px-3 py-4 text-center text-sm text-muted-foreground">No results found.</p>
          )}
          {results.map((sec) => (
            <div key={sec.group}>
              <p className="px-3 py-1.5 text-[10px] font-bold uppercase tracking-[0.14em] text-muted-foreground/70">{sec.group}</p>
              {sec.items.map((item) => (
                <button
                  key={item.label}
                  onClick={item.action}
                  className="flex w-full items-center justify-between gap-2 rounded-xl px-3 py-2.5 text-left text-sm transition-colors hover:bg-secondary focus-visible:outline-2 focus-visible:outline-ring"
                >
                  {item.label}
                  <ArrowRight className="h-3.5 w-3.5 text-muted-foreground opacity-50" />
                </button>
              ))}
            </div>
          ))}
        </div>
      </motion.div>
    </DialogShell>
  );
}

/* Minimal backdrop + portal shell (radix dialog removed to avoid dependency conflict). */
function DialogShell({
  open,
  onOpenChange,
  children,
}: {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  children: React.ReactNode;
}) {
  React.useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === "Escape") onOpenChange(false);
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [open, onOpenChange]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[14vh] px-4">
      <div className="absolute inset-0 bg-navy-950/40 backdrop-blur-sm" onClick={() => onOpenChange(false)} aria-hidden />
      {children}
    </div>
  );
}