"use client";

import * as React from "react";
import { motion, useReducedMotion } from "framer-motion";
import { ArrowRight, Clock, MapPin, Video } from "lucide-react";

import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { formatTime } from "@/lib/utils/cn";
import { instrumentIcon } from "@/lib/music-icons";
import { EASE, surfaceHover } from "@/lib/motion";
import type { ClassEvent } from "@/types";

export function ClassCard({
  cls,
  index = 0,
  onJoin,
  detail,
}: {
  cls: ClassEvent;
  index?: number;
  onJoin?: () => void;
  detail?: string;
}) {
  const reduced = useReducedMotion();
  const Icon = instrumentIcon(cls.instrument);

  return (
    <motion.div
      initial={{ opacity: 0, y: reduced ? 0 : 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-30px" }}
      transition={{ duration: 0.4, delay: index * 0.05, ease: EASE }}
      whileHover={reduced ? undefined : surfaceHover}
      className="group overflow-hidden rounded-2xl border border-border/60 bg-card transition-[box-shadow] duration-200 ease-ease-out-expo hover:shadow-soft"
    >
      <div className="flex items-center justify-between p-4 pb-2">
        <div className="flex items-center gap-3">
          <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-secondary text-muted-foreground transition-colors duration-200 group-hover:bg-accent group-hover:text-accent-foreground">
            <Icon className="h-5 w-5" />
          </span>
          <div>
            <p className="text-[15px] font-semibold leading-tight">{cls.title}</p>
            <p className="text-caption text-muted-foreground">{cls.instrument}</p>
          </div>
        </div>
        <Badge variant={cls.mode === "online" ? "mint" : "lavender"}>{cls.mode}</Badge>
      </div>

      <div className="px-4 pb-4">
        <div className="flex items-center gap-4 text-[13px] text-muted-foreground">
          <span className="flex items-center gap-1.5">
            <Clock className="h-3.5 w-3.5" />
            {formatTime(cls.start_time)} · {cls.duration_min} min
          </span>
          <span className="flex items-center gap-1.5">
            {cls.mode === "online" ? <Video className="h-3.5 w-3.5" /> : <MapPin className="h-3.5 w-3.5" />}
            {cls.room ?? cls.mode}
          </span>
        </div>

        <div className="mt-4 flex items-center gap-3 border-t border-border/60 pt-3">
          <Avatar name={cls.teacher_name} size="sm" />
          <span className="text-[13px] text-muted-foreground">
            with <span className="font-medium text-foreground">{cls.teacher_name}</span>
          </span>
          {onJoin && (
            <Button size="sm" className="ml-auto" onClick={onJoin}>
              {detail ?? "Join"} <ArrowRight className="h-4 w-4" />
            </Button>
          )}
        </div>
      </div>
    </motion.div>
  );
}