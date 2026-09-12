"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { BookOpen, FileMusic, Heart, Music, Search } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { AudioPlayer } from "@/components/music/audio-player";
import { cn } from "@/lib/utils/cn";

import { useAcademyData } from "@/hooks/use-academy-data";
import type { Resource } from "@/types";

const typeLabels: Partial<Record<Resource["type"], string>> = {
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

const allTypes = ["All", "Sheet Music", "Exercises", "Scales", "Chords", "Theory", "Songs", "Audio", "Video"] as const;

function typeIcon(t: Resource["type"]) {
  return t === "audio" ? <Music className="h-5 w-5" /> : t === "sheet_music" || t === "scales" || t === "song" ? <FileMusic className="h-5 w-5" /> : <BookOpen className="h-5 w-5" />;
}

export default function StudentLibraryPage() {
  const { resources } = useAcademyData();
  const [filter, setFilter] = React.useState<(typeof allTypes)[number]>("All");
  const [query, setQuery] = React.useState("");
  const [favorites, setFavorites] = React.useState<Set<string>>(new Set(resources.filter((r) => r.favorite).map((r) => r.id)));

  const filtered = resources.filter((r) => {
    const t = typeLabels[r.type];
    const matchesType = filter === "All" || t === filter;
    const matchesQuery = r.title.toLowerCase().includes(query.toLowerCase());
    return matchesType && matchesQuery;
  });

  const audioResources = filtered.filter((r) => r.type === "audio" && r.audio_url);
  const otherResources = filtered.filter((r) => !(r.type === "audio" && r.audio_url));

  const toggleFav = (id: string) => {
    setFavorites((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const FavHeart = ({ id }: { id: string }) => {
    const fav = favorites.has(id);
    return (
      <button
        onClick={() => { toggleFav(id); toast.success(fav ? "Removed from favorites" : "Added to favorites"); }}
        className="rounded-xl p-1.5 text-muted-foreground transition-colors hover:bg-secondary"
        aria-label="Toggle favorite"
      >
        <Heart className={cn("h-4 w-4", fav && "fill-peach-500 text-peach-500")} />
      </button>
    );
  };

  return (
    <div>
      <PageHeader title="Learning Library" subtitle="Sheets, exercises, theory and more." />

      <div className="mb-5 flex flex-col gap-3 md:flex-row md:items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input placeholder="Search resources..." className="pl-9" value={query} onChange={(e) => setQuery(e.target.value)} />
        </div>
        <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
          {allTypes.map((t) => (
            <button
              key={t}
              onClick={() => setFilter(t)}
              className={cn(
                "shrink-0 rounded-full px-4 py-1.5 text-sm font-medium transition-all",
                filter === t ? "bg-primary text-primary-foreground" : "bg-secondary text-muted-foreground hover:text-foreground",
              )}
            >
              {t}
            </button>
          ))}
        </div>
      </div>

      {audioResources.length > 0 && (
        <section className="mb-6">
          <SectionLabel text="Audio" />
          <div className="grid gap-4 lg:grid-cols-2">
            {audioResources.map((r) => (
              <div key={r.id} className="rounded-2xl border border-border/60 bg-card p-4">
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-lavender-100/70 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300">
                      <Music className="h-5 w-5" />
                    </div>
                    <div className="min-w-0">
                      <p className="truncate text-sm font-semibold">{r.title}</p>
                      <p className="truncate text-xs text-muted-foreground">{r.author ?? r.instrument} Ã‚Â· {r.level}</p>
                    </div>
                  </div>
                  <FavHeart id={r.id} />
                </div>
                <AudioPlayer src={r.audio_url!} className="mt-4" />
              </div>
            ))}
          </div>
        </section>
      )}

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {otherResources.map((r, i) => (
          <motion.div
            key={r.id}
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.04 }}
            whileHover={{ y: -3 }}
            className="group rounded-2xl border border-border/60 bg-card p-5 transition-shadow hover:shadow-soft"
          >
            <div className="flex items-start justify-between">
              <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-lavender-100/70 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300">
                {typeIcon(r.type)}
              </div>
              <FavHeart id={r.id} />
            </div>
            <p className="mt-4 font-semibold leading-snug">{r.title}</p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              {r.instrument} Ã‚Â· {r.level}
            </p>
            <div className="mt-3 flex items-center justify-between">
              <Badge variant="secondary">{typeLabels[r.type]}</Badge>
              <span className="text-xs text-muted-foreground">{r.duration_min ? `${r.duration_min} min` : r.author}</span>
            </div>
          </motion.div>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="flex flex-col items-center rounded-2xl border border-dashed border-border/70 bg-secondary/30 p-14 text-center">
          <Music className="mb-3 h-8 w-8 text-muted-foreground" />
          <p className="font-medium">No resources found</p>
          <p className="text-sm text-muted-foreground">Try a different search or filter.</p>
        </div>
      )}

      {favorites.size > 0 && (
        <section className="mt-8">
          <SectionLabel text="Favorites" />
          <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
            {resources.filter((r) => favorites.has(r.id)).map((r) => (
              <div key={r.id} className="flex w-56 shrink-0 items-center gap-3 rounded-2xl border border-border/60 bg-card p-4">
                <Heart className="h-4 w-4 shrink-0 fill-peach-500 text-peach-500" />
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium">{r.title}</p>
                  <p className="text-xs text-muted-foreground">{r.instrument}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}

function SectionLabel({ text }: { text: string }) {
  return <p className="mb-3 text-xs font-semibold uppercase tracking-[0.14em] text-muted-foreground/70">{text}</p>;
}