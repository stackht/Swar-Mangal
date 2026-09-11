"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { CheckCircle2, Circle, Sparkles } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";

import { assignments, students } from "@/lib/data/demo";
import type { Assignment } from "@/types";

export default function TeacherAssignmentsPage() {
  const [list, setList] = React.useState<Assignment[]>(assignments.filter((a) => a.teacher_id === "t1"));
  const [feedback, setFeedback] = React.useState("");
  const [reviewing, setReviewing] = React.useState<Assignment | null>(null);

  const submitted = list.filter((a) => a.status === "submitted");

  const review = (a: Assignment) => {
    setList((prev) => prev.map((x) => (x.id === a.id ? { ...x, status: "reviewed" as const } : x)));
    setReviewing(null);
    setFeedback("");
    toast.success("Assignment reviewed — feedback sent");
  };

  return (
    <div>
      <PageHeader title="Assignments" subtitle="Create and review student work." />

      <div className="mb-8">
        <Button onClick={() => toast.success("Assignment creator opened")}>
          <Sparkles className="h-4 w-4" /> New assignment
        </Button>
      </div>

      <section className="mb-8">
        <SectionHeader title={`Awaiting review (${submitted.length})`} />
        <div className="space-y-3">
          {submitted.length === 0 && <p className="rounded-3xl border bg-card p-8 text-center text-sm text-muted-foreground">Nothing to review — all caught up!</p>}
          {submitted.map((a, i) => {
            const student = students.find((s) => s.id === a.student_id);
            return (
              <motion.div
                key={a.id}
                initial={{ opacity: 0, y: 10 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05 }}
              >
                <Card>
                  <CardContent className="p-5">
                    <div className="flex flex-wrap items-center gap-3">
                      <CheckCircle2 className="h-5 w-5 text-lavender-600" />
                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-semibold">{a.title}</p>
                        <p className="text-xs text-muted-foreground">by {student?.full_name ?? "Student"} · submitted recently</p>
                      </div>
                      <Dialog open={reviewing?.id === a.id} onOpenChange={(o) => !o && setReviewing(null)}>
                        <DialogTrigger asChild>
                          <Button size="sm" onClick={() => setReviewing(a)}>Review & grade</Button>
                        </DialogTrigger>
                        <DialogContent>
                          <DialogHeader>
                            <DialogTitle>{a.title}</DialogTitle>
                            <DialogDescription>by {student?.full_name} — expected {a.expected_minutes} min</DialogDescription>
                          </DialogHeader>
                          <div className="space-y-4">
                            <div className="space-y-2">
                              <Label>Feedback</Label>
                              <Textarea value={feedback} onChange={(e) => setFeedback(e.target.value)} placeholder="Great work! Focus on..." rows={4} />
                            </div>
                            <div className="flex gap-2">
                              <Button variant="outline" className="flex-1">Request revision</Button>
                              <Button className="flex-1" disabled={!feedback.trim()} onClick={() => review(a)}>Approve & grade</Button>
                            </div>
                          </div>
                        </DialogContent>
                      </Dialog>
                      <Badge variant="lavender">submitted</Badge>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            );
          })}
        </div>
      </section>

      <section>
        <SectionHeader title="All assignments" />
        <div className="space-y-2">
          {list.filter((a) => a.status !== "submitted").map((a) => {
            const student = students.find((s) => s.id === a.student_id);
            return (
              <div key={a.id} className="flex items-center gap-4 rounded-2xl border bg-card p-4 shadow-card">
                <Circle className="h-4 w-4 text-muted-foreground/40" />
                <div className="flex-1">
                  <p className="text-sm font-medium">{a.title}</p>
                  <p className="text-xs text-muted-foreground">{student?.full_name} · due {new Date(a.due_date).toLocaleDateString()}</p>
                </div>
                <Badge variant={a.status === "reviewed" ? "mint" : "peach"}>{a.status}</Badge>
              </div>
            );
          })}
        </div>
      </section>
    </div>
  );
}