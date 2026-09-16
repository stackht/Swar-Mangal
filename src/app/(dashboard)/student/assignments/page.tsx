"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { CheckCircle2, Circle, FileText, Upload } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

import { useAcademyData } from "@/hooks/use-academy-data";
import type { Assignment } from "@/types";

const statusStyle: Record<Assignment["status"], { label: string; cls: string; variant: "lavender" | "mint" | "peach" | "secondary" | "destructive" | "default" | "outline" }> = {
  pending: { label: "Pending", cls: "bg-peach-100 text-peach-800", variant: "peach" },
  submitted: { label: "Submitted", cls: "bg-lavender-100 text-lavender-800", variant: "lavender" },
  reviewed: { label: "Reviewed", cls: "bg-mint-100 text-mint-800", variant: "mint" },
  overdue: { label: "Overdue", cls: "bg-destructive/10 text-destructive", variant: "destructive" },
};

export default function StudentAssignmentsPage() {
  const { assignments, refetch, isDemo , currentStudentId } = useAcademyData();
  const mine = assignments.filter((a) => a.student_id === currentStudentId);
  const [list, setList] = React.useState(mine);
  const [submitStep, setSubmitStep] = React.useState<Assignment | null>(null);
  const [note, setNote] = React.useState("");

  const submit = async (a: Assignment) => {
    if (!isDemo) {
      await fetch("/api/assignments", {
        method: "PATCH",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ id: a.id, status: "submitted" }),
      });
      await refetch();
    }
    setList((prev) => prev.map((x) => (x.id === a.id ? { ...x, status: "submitted" as const } : x)));
    setSubmitStep(null);
    setNote("");
    toast.success("Assignment submitted");
  };

  const pending = list.filter((a) => a.status === "pending" || a.status === "submitted");

  return (
    <div>
      <PageHeader title="Assignments" subtitle="Tasks from your teachers." />

      <SectionHeader title={`In progress (${pending.length})`} />
      <div className="space-y-4">
        {pending.length === 0 && (
          <p className="rounded-3xl border bg-card p-10 text-center text-sm text-muted-foreground">No pending assignments · all caught up!</p>
        )}
        {pending.map((a, i) => (
          <motion.div
            key={a.id}
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.05 }}
          >
            <Card>
              <CardContent className="p-5">
                <div className="flex items-start gap-4">
                  <div className="mt-0.5">
                    {a.status === "submitted" ? (
                      <CheckCircle2 className="h-5 w-5 text-lavender-600" />
                    ) : (
                      <Circle className="h-5 w-5 text-muted-foreground/40" />
                    )}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="font-semibold">{a.title}</p>
                      <Badge variant={statusStyle[a.status].variant}>{statusStyle[a.status].label}</Badge>
                      <Badge variant="secondary">{a.difficulty}</Badge>
                    </div>
                    <p className="mt-1 text-sm text-muted-foreground">{a.description}</p>
                    <p className="mt-2 text-xs text-muted-foreground">
                      by {a.teacher_name} · expected {a.expected_minutes} min · due{" "}
                      {new Date(a.due_date).toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" })}
                    </p>
                  </div>
                  <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
                    {a.status === "pending" && (
                      <Dialog open={submitStep?.id === a.id} onOpenChange={(o) => !o && setSubmitStep(null)}>
                        <DialogTrigger asChild>
                          <Button size="sm" onClick={() => setSubmitStep(a)}>
                            <Upload className="h-4 w-4" /> Submit
                          </Button>
                        </DialogTrigger>
                        <DialogContent>
                          <DialogHeader>
                            <DialogTitle>Submit assignment</DialogTitle>
                            <DialogDescription>{a.title}</DialogDescription>
                          </DialogHeader>
                          <div className="space-y-4">
                            <div className="space-y-2">
                              <Label>Add a note (optional)</Label>
                              <Input value={note} onChange={(e) => setNote(e.target.value)} placeholder="What did you work on?" />
                            </div>
                            <div className="rounded-2xl border border-dashed p-6 text-center text-sm text-muted-foreground">
                              <FileText className="mx-auto mb-2 h-6 w-6" />
                              Attach an audio, video, or sheet music file
                            </div>
                            <Button className="w-full" onClick={() => submit(a)}>
                              Submit
                            </Button>
                          </div>
                        </DialogContent>
                      </Dialog>
                    )}
                    {a.status === "submitted" && (
                      <span className="text-xs font-medium text-lavender-700">Awaiting review</span>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </div>

      <div className="mt-8">
        <SectionHeader title="Previously completed" />
        <div className="space-y-2">
          {list.filter((a) => a.status === "reviewed").map((a) => (
            <div key={a.id} className="flex items-center gap-4 rounded-2xl border bg-card p-4 shadow-card">
              <CheckCircle2 className="h-5 w-5 text-mint-600" />
              <div className="flex-1">
                <p className="text-sm font-medium">{a.title}</p>
                <p className="text-xs text-muted-foreground">Reviewed by {a.teacher_name}</p>
              </div>
              <Badge variant="mint">Reviewed</Badge>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}