"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Search, SearchX, UserPlus } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { Avatar } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";

import { useAcademyData } from "@/hooks/use-academy-data";
import type { Student } from "@/types";

export default function AdminStudentsPage() {
  const { students, instruments, refetch, isDemo } = useAcademyData();
  const [list, setList] = React.useState(students);
  const [query, setQuery] = React.useState("");
  const [newName, setNewName] = React.useState("");
  const [newInstrument, setNewInstrument] = React.useState("Piano");

  const filtered = list.filter(
    (s) =>
      s.full_name.toLowerCase().includes(query.toLowerCase()) ||
      s.instrument.toLowerCase().includes(query.toLowerCase()) ||
      s.level.toLowerCase().includes(query.toLowerCase()),
  );

  const addStudent = async () => {
    if (!newName.trim()) {
      toast.error("Enter a student name");
      return;
    }
    if (!isDemo) {
      await fetch("/api/students", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ full_name: newName.trim(), instrument: newInstrument }),
      });
      await refetch();
      setNewName("");
      toast.success("Student added");
      return;
    }
    const newStudent: Student = {
      id: `s-${Date.now()}`,
      email: `${newName.toLowerCase().replace(/\s+/g, ".")}@maestro.app`,
      full_name: newName.trim(),
      role: "student",
      avatar_url: null,
      instrument: newInstrument,
      level: "Beginner",
      fee_status: "pending",
    };
    setList((prev) => [newStudent, ...prev]);
    setNewName("");
    toast.success("Student added");
  };

  const removeStudent = async (id: string) => {
    if (!isDemo) {
      await fetch("/api/students", {
        method: "DELETE",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ id }),
      });
      await refetch();
      toast.success("Student removed");
      return;
    }
    setList((prev) => prev.filter((s) => s.id !== id));
    toast.success("Student removed");
  };

  return (
    <div>
      <PageHeader
        title="Students"
        subtitle={`${list.length} students enrolled`}
        actions={
          <Dialog>
            <DialogTrigger asChild>
              <Button><UserPlus className="h-4 w-4" /> Add student</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Add a student</DialogTitle>
                <DialogDescription>Create a student record in the academy.</DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div>
                  <label className="mb-1.5 block text-sm font-medium" htmlFor="sname">Full name</label>
                  <Input id="sname" value={newName} onChange={(e) => setNewName(e.target.value)} placeholder="e.g. Anaya Kapoor" />
                </div>
                <div>
                  <label className="mb-1.5 block text-sm font-medium" htmlFor="sinst">Instrument</label>
                  <select
                    id="sinst"
                    className="flex h-11 w-full rounded-2xl border bg-background px-4 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    value={newInstrument}
                    onChange={(e) => setNewInstrument(e.target.value)}
                  >
                    {instruments.map((i) => <option key={i.id} value={i.name}>{i.name}</option>)}
                  </select>
                </div>
                <Button className="w-full" onClick={addStudent}>Add student</Button>
              </div>
            </DialogContent>
          </Dialog>
        }
      />

      <div className="relative mb-5 max-w-md">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input placeholder="Search students..." className="pl-9" value={query} onChange={(e) => setQuery(e.target.value)} />
      </div>

      {/* Desktop table */}
      <div className="hidden overflow-hidden rounded-2xl border border-border/60 bg-card lg:block">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b bg-secondary/40 text-left text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              <th className="px-5 py-3">Student</th>
              <th className="px-5 py-3">Instrument</th>
              <th className="px-5 py-3">Level</th>
              <th className="px-5 py-3">Fees</th>
              <th className="px-5 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((s, i) => (
              <motion.tr
                key={s.id}
                initial={{ opacity: 0 }}
                whileInView={{ opacity: 1 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.03 }}
                className="border-b border-border/50 last:border-0 hover:bg-secondary/40"
              >
                <td className="px-5 py-3">
                  <div className="flex items-center gap-3">
                    <Avatar name={s.full_name} size="sm" />
                    <div>
                      <p className="font-medium">{s.full_name}</p>
                      <p className="text-xs text-muted-foreground">{s.email}</p>
                    </div>
                  </div>
                </td>
                <td className="px-5 py-3 text-muted-foreground">{s.instrument}</td>
                <td className="px-5 py-3">
                  <Badge variant="secondary">{s.level}</Badge>
                </td>
                <td className="px-5 py-3">
                  <Badge variant={s.fee_status === "paid" ? "mint" : s.fee_status === "pending" ? "lavender" : "peach"}>{s.fee_status}</Badge>
                </td>
                <td className="px-5 py-3 text-right">
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-destructive hover:text-destructive"
                    onClick={() => removeStudent(s.id)}
                  >
                    Remove
                  </Button>
                </td>
              </motion.tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Mobile cards */}
      <div className="space-y-3 lg:hidden">
        {filtered.map((s, i) => (
          <motion.div
            key={s.id}
            initial={{ opacity: 0, y: 8 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.03 }}
            className="rounded-2xl border border-border/60 bg-card p-4"
          >
            <div className="flex items-center gap-3">
              <Avatar name={s.full_name} />
              <div className="min-w-0 flex-1">
                <p className="truncate font-medium">{s.full_name}</p>
                <p className="truncate text-xs text-muted-foreground">{s.email}</p>
              </div>
              <Badge variant={s.fee_status === "paid" ? "mint" : s.fee_status === "pending" ? "lavender" : "peach"}>{s.fee_status}</Badge>
            </div>
            <div className="mt-3 flex items-center gap-2">
              <Badge variant="secondary">{s.instrument}</Badge>
              <Badge variant="secondary">{s.level}</Badge>
              <Button
                variant="ghost"
                size="sm"
                className="ml-auto text-destructive hover:text-destructive"
                onClick={() => removeStudent(s.id)}
              >
                Remove
              </Button>
            </div>
          </motion.div>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="flex flex-col items-center rounded-2xl border border-dashed border-border/70 bg-secondary/30 p-12 text-center">
          <SearchX className="mb-2 h-8 w-8 text-muted-foreground" />
          <p className="font-medium">No students found</p>
          <p className="text-sm text-muted-foreground">Try a different search.</p>
        </div>
      )}
    </div>
  );
}