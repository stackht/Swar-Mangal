"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion, useReducedMotion } from "framer-motion";
import { LogOut } from "lucide-react";

import { navByRole } from "@/lib/config/navigation";
import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils/cn";

export function Sidebar() {
  const pathname = usePathname();
  const reduced = useReducedMotion();
  const { user, role, logout } = useAuth();
  if (!role || !user) return null;
  const sections = navByRole[role];

  return (
    <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 flex-col border-r border-border/60 bg-background lg:flex">
      <div className="flex h-16 items-center gap-2.5 border-b border-border/50 px-5">
        <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-gradient-to-br from-lavender-500 to-mint-500 text-white shadow-xs">
          <span className="text-[15px] font-bold tracking-tight">S</span>
        </div>
        <span className="text-[17px] font-semibold tracking-tight">Swar Mangal</span>
      </div>

      <nav className="flex-1 space-y-6 overflow-y-auto px-3 py-4">
        {sections.map((section, i) => (
          <div key={i}>
            {section.label && (
              <p className="mb-1.5 px-3 text-[10px] font-semibold uppercase tracking-[0.14em] text-muted-foreground/70">
                {section.label}
              </p>
            )}
            <div className="space-y-0.5">
              {section.items.map((item) => {
                const active =
                  item.href === `/${role}` ? pathname === item.href : pathname.startsWith(item.href);
                const Icon = item.icon;
                return (
                  <Link key={item.href} href={item.href} className="relative block" aria-current={active ? "page" : undefined}>
                    <span
                      className={cn(
                        "relative flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-medium transition-colors duration-200",
                        active ? "text-foreground" : "text-muted-foreground hover:bg-secondary/80 hover:text-foreground",
                      )}
                    >
                      {active && (
                        <motion.span
                          layoutId={`sb-active-${role}`}
                          className="absolute inset-0 rounded-xl bg-secondary"
                          transition={reduced ? { duration: 0 } : { type: "spring", stiffness: 380, damping: 32, mass: 0.6 }}
                        />
                      )}
                      <Icon className={cn("relative h-[18px] w-[18px] transition-colors", active && "text-primary")} />
                      <span className="relative">{item.title}</span>
                    </span>
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      <div className="border-t border-border/50 p-3">
        <div className="flex items-center gap-3 rounded-xl px-2 py-2">
          <Avatar name={user.full_name} src={user.avatar_url} size="sm" />
          <div className="min-w-0 flex-1">
            <p className="truncate text-[13px] font-semibold leading-tight">{user.full_name}</p>
            <p className="truncate text-[11px] capitalize text-muted-foreground">{role}</p>
          </div>
          <Button variant="ghost" size="iconSm" onClick={logout} aria-label="Log out">
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </aside>
  );
}