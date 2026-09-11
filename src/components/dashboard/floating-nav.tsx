"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion, useReducedMotion } from "framer-motion";

import { mobileNav } from "@/lib/config/navigation";
import { useAuth } from "@/components/auth/auth-provider";
import { cn } from "@/lib/utils/cn";

/**
 * Premium floating capsule bottom nav for mobile.
 * Glass surface, floating above content, animated active indicator.
 */
export function FloatingNav() {
  const pathname = usePathname();
  const reduced = useReducedMotion();
  const { role } = useAuth();
  if (!role) return null;
  const items = mobileNav(role).filter(Boolean);

  return (
    <nav
      className="fixed inset-x-0 bottom-4 z-40 flex justify-center px-4 lg:hidden"
      aria-label="Primary"
    >
      <div className="flex items-center gap-0.5 rounded-full border border-white/10 bg-background/85 px-1.5 py-1.5 shadow-float backdrop-blur-2xl dark:border-white/[0.06] dark:bg-white/[0.08]">
        {items.map((item) => {
          const active = pathname.startsWith(item.href);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              aria-label={item.title}
              className="relative flex flex-1 items-center justify-center"
            >
              {active && (
                <motion.span
                  layoutId={`floating-${role}`}
                  className="absolute inset-x-0 -inset-y-1 rounded-full bg-primary/15"
                  transition={reduced ? { duration: 0 } : { type: "spring", stiffness: 400, damping: 34, mass: 0.6 }}
                />
              )}
              <span className={cn(
                "relative z-10 flex h-11 w-11 items-center justify-center rounded-full transition-colors",
                active ? "text-primary" : "text-muted-foreground",
              )}>
                <Icon className="h-5 w-5" strokeWidth={active ? 2.2 : 1.8} />
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}