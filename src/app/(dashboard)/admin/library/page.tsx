"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { BookOpen, FileMusic, Music, Trash2 } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { SectionHeader } from "@/components/dashboard/section-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

import { useAcademyData } from "@/hooks/use-academy-data";
import type { Resource } from "@/types";

const typeLabels: Record<Resource["type"], string> = {
  sheet_music: "Sheet Music",
  exercise: "Exercises",
  scales: "Scales",
  chords: "Chords",
  theory: "Theory",
  song: "Songs",
  audio: "Audio",
  video: "Video",
  lesson: "Lessons",
};

export default function AdminLibraryPage() {
  const { resources } = useAcademyData();
  const [list, setList] = React.useState(resources);
  return (
    <div>
      <PageHeader
        title="Learning Materials"
        subtitle="All academy resources."
        actions={<Button onClick={() => toast.success("Upload flow opened")}><FileMusic className="h-4 w-4" /> Upload</Button>}
      />
      <section>
        <SectionHeader title={`${list.length} resources`} />
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {list.map((r, i) => (
            <motion.div key={r.id} initial={{ opacity: 0, y: 12 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.04 }} whileHover={{ y: -3 }} className="rounded-3xl border bg-card p-5 shadow-card">
              <div className="flex items-start justify-between">
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-lavender-100 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300">
                  {r.type === "audio" ? <Music className="h-5 w-5" /> : r.type === "sheet_music" || r.type === "scales" || r.type === "song" ? <FileMusic className="h-5 w-5" /> : <BookOpen className="h-5 w-5" />}
                </div>
                <button onClick={() => setList((prev) => prev.filter((x) => x.id !== r.id))} className="rounded-xl p-1.5 text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive" aria-label="Delete">
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
              <p className="mt-4 font-semibold leading-snug">{r.title}</p>
              <p className="mt-0.5 text-xs text-muted-foreground">{r.instrument} Ã‚Â· {r.level}</p>
              <div className="mt-3"><Badge variant="secondary">{typeLabels[r.type]}</Badge></div>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  );
}