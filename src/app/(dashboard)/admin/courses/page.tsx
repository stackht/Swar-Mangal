"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { BookOpen, Plus } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";

import { instruments } from "@/lib/data/demo";

const initialCourses = [
  { id: "co1", name: "Piano Fundamentals", instrument: "Piano", level: "Beginner", color: "#8d6bf6" },
  { id: "co2", name: "Piano Advanced", instrument: "Piano", level: "Advanced", color: "#8d6bf6" },
  { id: "co3", name: "Guitar Beginner", instrument: "Guitar", level: "Beginner", color: "#2dbd7f" },
  { id: "co4", name: "Guitar Intermediate", instrument: "Guitar", level: "Intermediate", color: "#2dbd7f" },
  { id: "co5", name: "Vocal Training", instrument: "Vocals", level: "Intermediate", color: "#e0608a" },
  { id: "co6", name: "Violin Essentials", instrument: "Violin", level: "Beginner", color: "#ff8f3f" },
  { id: "co7", name: "Music Theory", instrument: "All", level: "All", color: "#5b8def" },
  { id: "co8", name: "Drum Basics", instrument: "Drums", level: "Beginner", color: "#5b8def" },
];

export default function AdminCoursesPage() {
  const [courses, setCourses] = React.useState(initialCourses);
  const [name, setName] = React.useState("");
  const [instrument, setInstrument] = React.useState("Piano");

  const add = () => {
    if (!name.trim()) {
      toast.error("Enter a course name");
      return;
    }
    setCourses((prev) => [...prev, { id: `co-${Date.now()}`, name: name.trim(), instrument, level: "Beginner", color: "#8d6bf6" }]);
    setName("");
    toast.success("Course created");
  };

  return (
    <div>
      <PageHeader
        title="Courses"
        subtitle={`${courses.length} courses offered`}
        actions={
          <Dialog>
            <DialogTrigger asChild>
              <Button><Plus className="h-4 w-4" /> New course</Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Create a course</DialogTitle>
                <DialogDescription>Add a new program to the academy.</DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="space-y-2">
                  <label className="block text-sm font-medium" htmlFor="cname">Course name</label>
                  <Input id="cname" value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Jazz Piano" />
                </div>
                <div className="space-y-2">
                  <label className="block text-sm font-medium" htmlFor="cinstr">Instrument</label>
                  <select id="cinstr" className="flex h-11 w-full rounded-2xl border bg-background px-4 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" value={instrument} onChange={(e) => setInstrument(e.target.value)}>
                    {instruments.map((i) => <option key={i.id} value={i.name}>{i.name}</option>)}
                  </select>
                </div>
                <Button className="w-full" onClick={add}>Create course</Button>
              </div>
            </DialogContent>
          </Dialog>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {courses.map((c, i) => (
          <motion.div
            key={c.id}
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.04 }}
            whileHover={{ y: -3 }}
            className="rounded-3xl border bg-card p-5 shadow-card"
          >
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl" style={{ backgroundColor: `${c.color}22`, color: c.color }}>
              <BookOpen className="h-5 w-5" />
            </div>
            <p className="mt-4 font-semibold">{c.name}</p>
            <p className="text-xs text-muted-foreground">{c.instrument}</p>
            <div className="mt-3">
              <Badge variant="secondary">{c.level}</Badge>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}