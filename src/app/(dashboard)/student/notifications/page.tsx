"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Bell, CalendarClock, Check, CheckCheck, Megaphone, Music } from "lucide-react";

import { PageHeader } from "@/components/dashboard/page-header";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils/cn";

import { notifications } from "@/lib/data/demo";

const typeIcon: Record<string, React.ReactNode> = {
  class: <CalendarClock className="h-5 w-5" />,
  assignment: <CheckCheck className="h-5 w-5" />,
  practice: <Music className="h-5 w-5" />,
  announcement: <Megaphone className="h-5 w-5" />,
};

export default function StudentNotificationsPage() {
  const [items, setItems] = React.useState(notifications);

  const markAll = () => setItems((prev) => prev.map((n) => ({ ...n, read: true })));
  const markOne = (id: string) => setItems((prev) => prev.map((n) => (n.id === id ? { ...n, read: true } : n)));

  return (
    <div>
      <PageHeader
        title="Notifications"
        subtitle="Stay up to date."
        actions={<Button variant="outline" size="sm" onClick={markAll}><Check className="h-4 w-4" /> Mark all read</Button>}
      />

      <div className="space-y-2">
        {items.map((n, i) => (
          <motion.button
            key={n.id}
            initial={{ opacity: 0, y: 8 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.04 }}
            onClick={() => markOne(n.id)}
            className={cn(
              "flex w-full items-start gap-4 rounded-2xl border p-4 text-left shadow-card transition-colors",
              !n.read && "bg-lavender-50 dark:bg-lavender-500/10",
            )}
          >
            <div className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-secondary text-muted-foreground">
              {typeIcon[n.type] ?? <Bell className="h-5 w-5" />}
              {!n.read && <span className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-peach-500" />}
            </div>
            <div className="flex-1">
              <p className={cn("text-sm", n.read ? "text-muted-foreground" : "font-semibold")}>{n.title}</p>
              <p className="mt-0.5 text-xs text-muted-foreground">{n.body}</p>
            </div>
            <span className="text-[10px] text-muted-foreground">
              {new Date(n.created_at).toLocaleDateString(undefined, { month: "short", day: "numeric" })}
            </span>
          </motion.button>
        ))}
      </div>
    </div>
  );
}