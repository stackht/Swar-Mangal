"use client";

import Link from "next/link";
import { Bell, CalendarDays, Moon, Search, Sun } from "lucide-react";
import { useTheme } from "next-themes";

import { useAuth } from "@/components/auth/auth-provider";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";

export function Header() {
  const { user, role, logout } = useAuth();
  const { theme, setTheme } = useTheme();
  const notifBase = `/${role}/notifications`;
  const scheduleBase = `/${role}/schedule`;

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center gap-2 border-b bg-background/80 px-4 backdrop-blur-xl lg:px-8">
      <div className="lg:hidden flex items-center gap-2 mr-2">
        <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-gradient-to-br from-lavender-400 to-mint-400 text-white">
          <span className="text-sm font-bold">M</span>
        </div>
      </div>

      <div className="hidden flex-1 items-center gap-2 rounded-2xl bg-secondary px-3 py-2 md:flex md:max-w-sm">
        <Search className="h-4 w-4 text-muted-foreground" />
        <input
          placeholder="Search..."
          className="w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
          aria-label="Search"
        />
      </div>

      <div className="ml-auto flex items-center gap-1.5">
        <Button
          variant="ghost"
          size="icon"
          aria-label="Toggle theme"
          onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
        >
          {theme === "dark" ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
        </Button>
        <Button variant="ghost" size="icon" aria-label="Toggle theme">
          {theme === "dark" ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
        </Button>
        <Link
          href={scheduleBase}
          aria-label="Schedule"
          className="inline-flex h-10 w-10 items-center justify-center rounded-xl text-foreground transition-all hover:bg-secondary active:scale-95"
        >
          <CalendarDays className="h-5 w-5" />
        </Link>
        <Link
          href={notifBase}
          aria-label="Notifications"
          className="relative inline-flex h-10 w-10 items-center justify-center rounded-xl text-foreground transition-all hover:bg-secondary active:scale-95"
        >
          <Bell className="h-5 w-5" />
          <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-peach-500" />
        </Link>

        {user && (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button className="ml-1 rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" aria-label="Account">
                <Avatar name={user.full_name} src={user.avatar_url} />
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56">
              <DropdownMenuLabel>
                <p className="font-semibold">{user.full_name}</p>
                <p className="text-xs font-normal text-muted-foreground capitalize">{role}</p>
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem asChild><Link href={`/${role}/profile`}>Profile</Link></DropdownMenuItem>
              <DropdownMenuItem asChild><Link href={notifBase}>Notifications</Link></DropdownMenuItem>
              <DropdownMenuItem asChild><Link href={scheduleBase}>Schedule</Link></DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={logout}>Log out</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        )}
      </div>
    </header>
  );
}
