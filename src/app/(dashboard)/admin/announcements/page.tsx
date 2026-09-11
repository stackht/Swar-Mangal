"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Megaphone, Pin } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";

import { announcements } from "@/lib/data/demo";

export default function AdminAnnouncementsPage() {
  const [list, setList] = React.useState(announcements);
  const [title, setTitle] = React.useState("");
  const [body, setBody] = React.useState("");
  const [audience, setAudience] = React.useState("All students");

  const publish = () => {
    if (!title.trim()) {
      toast.error("Add a title");
      return;
    }
    setList((prev) => [
      { id: `an-${Date.now()}`, title: title.trim(), body: body.trim() || "—", author: "The Swar Mangal Team", created_at: new Date().toISOString(), audience },
      ...prev,
    ]);
    setTitle("");
    setBody("");
    toast.success("Announcement published");
  };

  return (
    <div>
      <PageHeader
        title="Announcements"
        subtitle={`${list.length} published`}
        actions={
          <Dialog>
            <DialogTrigger asChild>
              <Button><Megaphone className="h-4 w-4" /> New announcement</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Post announcement</DialogTitle>
                <DialogDescription>Share news with the academy.</DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="space-y-2">
                  <label className="block text-sm font-medium" htmlFor="atitle">Title</label>
                  <Input id="atitle" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Summer recital" />
                </div>
                <div className="space-y-2">
                  <label className="block text-sm font-medium" htmlFor="abody">Message</label>
                  <Textarea id="abody" value={body} onChange={(e) => setBody(e.target.value)} rows={3} placeholder="Details..." />
                </div>
                <div className="space-y-2">
                  <label className="block text-sm font-medium" htmlFor="aaud">Audience</label>
                  <select id="aaud" className="flex h-11 w-full rounded-2xl border bg-background px-4 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" value={audience} onChange={(e) => setAudience(e.target.value)}>
                    {["All students", "All teachers", "Piano students", "Everyone"].map((a) => <option key={a}>{a}</option>)}
                  </select>
                </div>
                <Button className="w-full" onClick={publish}>Publish</Button>
              </div>
            </DialogContent>
          </Dialog>
        }
      />

      <div className="space-y-3">
        {list.map((a, i) => (
          <motion.div key={a.id} initial={{ opacity: 0, y: 10 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.04 }}>
            <Card>
              <CardContent className="p-5">
                <div className="flex items-start gap-4">
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-lavender-100 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300">
                    <Megaphone className="h-5 w-5" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="font-semibold">{a.title}</p>
                      {a.pinned && <Badge variant="lavender"><Pin className="h-3 w-3" /> Pinned</Badge>}
                      <Badge variant="secondary">{a.audience}</Badge>
                    </div>
                    <p className="mt-1 text-sm text-muted-foreground">{a.body}</p>
                    <p className="mt-2 text-xs text-muted-foreground">
                      {a.author} · {new Date(a.created_at).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" })}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </div>
    </div>
  );
}