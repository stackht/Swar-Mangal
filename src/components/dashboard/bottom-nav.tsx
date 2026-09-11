"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion, useReducedMotion } from "framer-motion";

import { mobileNav } from "@/lib/config/navigation";
import { useAuth } from "@/components/auth/auth-provider";
import { cn } from "@/lib/utils/cn";

export function BottomNav() {
  const pathname = usePathname();
  const reduced = useReducedMotion();
  const { role } = useAuth();
  if (!role) return null;
  const items = mobileNav(role).filter(Boolean);

  return (
    <nav
      className="fixed inset-x-0 bottom-0 z-30 border-t border-border/60 bg-background/85 backdrop-blur-xl lg:hidden"
      aria-label="Primary"
    >
      <div className="mx-auto flex max-w-md items-center justify-around px-2 pb-[env(safe-area-inset-bottom)] pt-1.5">
        {items.map((item) => {
          const active = pathname.startsWith(item.href);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              aria-current={active ? "page" : undefined}
              className="relative flex flex-1 flex-col items-center gap-1 rounded-2xl py-1"
            >
              {active && (
                <motion.span
                  layoutId={`bottom-active-${role}`}
                  className="absolute inset-0 rounded-2xl bg-lavender-100/80 dark:bg-lavender-500/15"
                  transition={reduced ? { duration: 0 } : { type: "spring", stiffness: 400, damping: 32 }}
                />
              )}
              <Icon className={cn("relative z-10 h-5 w-5 transition-colors", active ? "text-lavender-700 dark:text-lavender-300" : "text-muted-foreground")} />
              <span className={cn("relative z-10 text-[10px] font-medium transition-colors", active ? "text-lavender-700 dark:text-lavender-300" : "text-muted-foreground")}>
                {item.title}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
