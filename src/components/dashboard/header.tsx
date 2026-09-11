"use client";

import Link from "next/link";
import { Bell, CalendarDays } from "lucide-react";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { ThemeToggle } from "@/components/ui/theme-toggle";
import { useCommandPalette } from "@/components/command/command-palette";

export function Header() {
  const { user, role } = useAuth();
  const { open: openCmd } = useCommandPalette();
  const notifBase = `/${role}/notifications`;
  const scheduleBase = `/${role}/schedule`;

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center gap-2 border-b border-border/60 bg-background/80 px-4 backdrop-blur-xl lg:px-8">
      <div className="lg:hidden flex items-center gap-2 mr-2">
        <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-gradient-to-br from-lavender-500 to-mint-500 text-white">
          <span className="text-sm font-bold">S</span>
        </div>
      </div>

      <button
        onClick={() => openCmd(true)}
        className="hidden items-center gap-2 rounded-2xl border border-border/60 bg-secondary/70 px-3 py-2 text-sm text-muted-foreground transition-colors hover:border-border hover:bg-secondary md:flex md:w-full md:max-w-sm"
        aria-label="Search or run a command"
      >
        <SearchIcon className="h-4 w-4" />
        <span className="flex-1 text-left">Search…</span>
        <span className="flex items-center gap-0.5 text-[10px]">
          <kbd className="rounded-md border border-border bg-background px-1 py-0.5 font-semibold">⌘</kbd>
          <kbd className="rounded-md border border-border bg-background px-1 py-0.5 font-semibold">K</kbd>
        </span>
      </button>

      <div className="ml-auto flex items-center gap-1">
        <ThemeToggle />
        <Button variant="ghost" size="icon" aria-label="Schedule" asChild>
          <Link href={scheduleBase}><CalendarDays className="h-5 w-5" /></Link>
        </Button>
        <Button variant="ghost" size="icon" aria-label="Notifications" asChild className="relative">
          <Link href={notifBase}>
            <Bell className="h-5 w-5" />
            <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-peach-500 ring-2 ring-background" />
          </Link>
        </Button>

        {user && (
          <div className="ml-1 flex items-center gap-2 rounded-full p-1 transition-colors hover:bg-secondary">
            <Link href={`/${role}/profile`} aria-label="Profile">
              <Avatar name={user.full_name} src={user.avatar_url} />
            </Link>
          </div>
        )}
      </div>
    </header>
  );
}

function SearchIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" />
    </svg>
  );
}