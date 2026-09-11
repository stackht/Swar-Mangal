"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { CalendarClock, Check, CheckCheck, Download, Megaphone, Users } from "lucide-react";

import { PageHeader } from "@/components/dashboard/page-header";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils/cn";

const items = [
  { id: "n1", title: "New student enrolled", body: "Priya Nair joined Piano (Grade 5)", created_at: new Date(Date.now() - 5 * 3600e3).toISOString(), read: false, type: "student" },
  { id: "n2", title: "Payment received", body: "Aarav paid October tuition ($120)", created_at: new Date(Date.now() - 864e5).toISOString(), read: false, type: "payment" },
  { id: "n3", title: "Class created", body: "Vocal Training scheduled by Emma Davis", created_at: new Date(Date.now() - 2 * 864e5).toISOString(), read: true, type: "class" },
];

const typeIcon: Record<string, React.ReactNode> = {
  student: <Users className="h-5 w-5" />,
  payment: <Download className="h-5 w-5" />,
  class: <CalendarClock className="h-5 w-5" />,
  announcement: <Megaphone className="h-5 w-5" />,
};

export default function AdminNotificationsPage() {
  const [list, setList] = React.useState(items);
  return (
    <div>
      <PageHeader title="Notifications" subtitle="Academy-wide updates." actions={<Button variant="outline" size="sm" onClick={() => setList((prev) => prev.map((n) => ({ ...n, read: true })))}><Check className="h-4 w-4" /> Mark all read</Button>} />
      <div className="space-y-2">
        {list.map((n, i) => (
          <motion.div key={n.id} initial={{ opacity: 0, y: 8 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.04 }} className={cn("flex items-start gap-4 rounded-2xl border p-4 shadow-card", !n.read && "bg-lavender-50 dark:bg-lavender-500/10")}>
            <div className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-secondary text-muted-foreground">
              {typeIcon[n.type] ?? <CheckCheck className="h-5 w-5" />}
              {!n.read && <span className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-peach-500" />}
            </div>
            <div className="flex-1">
              <p className={cn("text-sm", !n.read && "font-semibold")}>{n.title}</p>
              <p className="text-xs text-muted-foreground">{n.body}</p>
            </div>
            <span className="text-[10px] text-muted-foreground">{new Date(n.created_at).toLocaleDateString()}</span>
          </motion.div>
        ))}
      </div>
    </div>
  );
}