"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { MessageSquare, Search } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { Avatar } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function TeacherStudentsPage() {
const { students, practice, progress: skillProgress, feedback, classes, currentTeacherId } = useAcademyData();
  const rosterIds = new Set(classes.filter((c) => c.teacher_id === currentTeacherId).flatMap((c) => c.student_ids));
  const myStudents = students.filter((s) => rosterIds.has(s.id));
  const [query, setQuery] = React.useState("");
  const [selected, setSelected] = React.useState<string | null>(null);
  const [fb, setFb] = React.useState("");

  const filtered = myStudents.filter((s) => s.full_name.toLowerCase().includes(query.toLowerCase()));

  const practiceMins = (id: string) =>
    practice.filter((p) => p.student_id === id && new Date(p.date) >= new Date(Date.now() - 7 * 864e5)).reduce((x, p) => x + p.minutes, 0);

  return (
    <div>
      <PageHeader title="My Students" subtitle="Track progress and stay in touch." />

      <div className="relative mb-5 max-w-md">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input placeholder="Search students..." className="pl-9" value={query} onChange={(e) => setQuery(e.target.value)} />
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {filtered.map((s, i) => {
          const mins = practiceMins(s.id);
          const totalFeedback = feedback.filter((f) => f.student_id === s.id).length;
          return (
            <motion.div
              key={s.id}
              initial={{ opacity: 0, y: 12 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.05 }}
              whileHover={{ y: -3 }}
              className="rounded-3xl border bg-card p-5 shadow-card transition-shadow hover:shadow-soft-lg"
            >
              <div className="flex items-center gap-3">
                <Avatar name={s.full_name} size="lg" />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold">{s.full_name}</p>
                  <p className="text-xs text-muted-foreground">{s.instrument} � {s.level}</p>
                </div>
                <Badge variant={s.fee_status === "paid" ? "mint" : s.fee_status === "pending" ? "lavender" : "peach"}>{s.fee_status}</Badge>
              </div>

              <div className="mt-4">
                <div className="mb-1 flex justify-between text-xs text-muted-foreground">
                  <span>Practice week</span>
                  <span className="font-medium">{mins} / 120 min</span>
                </div>
                <Progress value={Math.min(100, (mins / 120) * 100)} indicatorClassName="bg-gradient-to-r from-lavender-400 to-mint-400" />
              </div>

              <div className="mt-3 flex items-center justify-between text-xs text-muted-foreground">
                <span>Overall skill: <span className="font-semibold text-foreground">{skillProgress.overall}%</span></span>
                <span>{totalFeedback} feedback notes</span>
              </div>

              <div className="mt-4 flex gap-2">
                <Dialog open={selected === s.id} onOpenChange={(o) => !o && setSelected(null)}>
                  <DialogTrigger asChild>
                    <Button size="sm" variant="secondary" className="flex-1" onClick={() => setSelected(s.id)}>
                      Add feedback
                    </Button>
                  </DialogTrigger>
                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>Feedback for {s.full_name}</DialogTitle>
                      <DialogDescription>Notes on their latest lesson.</DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4">
                      <div className="space-y-2">
                        <Label htmlFor="fb">Feedback</Label>
                        <Textarea id="fb" value={fb} onChange={(e) => setFb(e.target.value)} placeholder="What went well? What to work on?" rows={4} />
                      </div>
                      <Button className="w-full" disabled={!fb.trim()} onClick={() => {
                        toast.success(`Feedback sent to ${s.full_name}`);
                        setFb("");
                        setSelected(null);
                      }}>
                        Send feedback
                      </Button>
                    </div>
                  </DialogContent>
                </Dialog>
                <Button size="sm" className="flex-1" onClick={() => toast.success("Opening chat")}>
                  <MessageSquare className="h-4 w-4" /> Message
                </Button>
              </div>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}