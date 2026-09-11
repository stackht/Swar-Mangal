"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Send } from "lucide-react";

import { Avatar } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils/cn";

import { messages, threads } from "@/lib/data/demo";
import type { Message } from "@/types";

export function MessagesView({ currentUserId, currentName }: { currentUserId: string; currentName: string }) {
  const [activeThreadId, setActiveThreadId] = React.useState(threads[0]?.id ?? null);
  const [convo, setConvo] = React.useState<Record<string, Message[]>>({
    th1: messages,
    th2: [],
  });
  const [draft, setDraft] = React.useState("");

  const active = threads.find((t) => t.id === activeThreadId);
  const activeMessages = active ? convo[active.id] ?? [] : [];

  const send = () => {
    if (!draft.trim() || !active) return;
    const msg: Message = {
      id: `m-${Date.now()}`,
      thread_id: active.id,
      sender_id: currentUserId,
      sender_name: currentName,
      body: draft.trim(),
      created_at: new Date().toISOString(),
    };
    setConvo((prev) => ({ ...prev, [active.id]: [...(prev[active.id] ?? []), msg] }));
    setDraft("");
  };

  return (
    <div className="grid gap-4 lg:grid-cols-[320px_1fr]">
      <div className="space-y-2">
        {threads.map((t) => {
          const other = t.participant_names.find((n) => n !== currentName) ?? t.participant_names[0];
          return (
            <button
              key={t.id}
              onClick={() => setActiveThreadId(t.id)}
              className={cn(
                "flex w-full items-center gap-3 rounded-2xl border p-4 text-left transition-all",
                activeThreadId === t.id ? "border-transparent bg-primary text-primary-foreground shadow-soft" : "bg-card hover:-translate-y-0.5 hover:shadow-card",
              )}
            >
              <Avatar name={other} size="md" />
              <div className="min-w-0 flex-1">
                <p className={cn("truncate text-sm font-semibold", activeThreadId === t.id && "text-primary-foreground")}>{other}</p>
                <p className={cn("truncate text-xs", activeThreadId === t.id ? "text-primary-foreground/70" : "text-muted-foreground")}>
                  {t.last_message}
                </p>
              </div>
              {t.unread ? (
                <span className={cn("flex h-5 min-w-5 items-center justify-center rounded-full px-1.5 text-[10px] font-bold", activeThreadId === t.id ? "bg-primary-foreground text-primary" : "bg-peach-500 text-white")}>
                  {t.unread}
                </span>
              ) : null}
            </button>
          );
        })}
      </div>

      <div className="flex flex-col rounded-3xl border bg-card shadow-card lg:h-[520px]">
        <div className="flex items-center gap-3 border-b p-4">
          <Avatar name={active?.participant_names.find((n) => n !== currentName) ?? "Teacher"} size="md" />
          <div>
            <p className="text-sm font-semibold">{active?.participant_names.find((n) => n !== currentName)}</p>
            <p className="text-xs text-muted-foreground">Online</p>
          </div>
        </div>

        <div className="flex-1 space-y-3 overflow-y-auto p-4">
          {activeMessages.length === 0 && (
            <p className="pt-10 text-center text-sm text-muted-foreground">Say hello to start the conversation.</p>
          )}
          {activeMessages.map((m) => {
            const mine = m.sender_id === currentUserId;
            return (
              <motion.div
                key={m.id}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                className={cn("flex", mine ? "justify-end" : "justify-start")}
              >
                <div
                  className={cn(
                    "max-w-[80%] rounded-2xl px-4 py-2.5 text-sm shadow-card",
                    mine ? "rounded-br-md bg-primary text-primary-foreground" : "rounded-bl-md bg-secondary",
                  )}
                >
                  <p>{m.body}</p>
                  <p className={cn("mt-1 text-[10px]", mine ? "text-primary-foreground/60" : "text-muted-foreground")}>
                    {new Date(m.created_at).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}
                  </p>
                </div>
              </motion.div>
            );
          })}
        </div>

        <div className="flex items-center gap-2 border-t p-3">
          <Input
            placeholder="Write a message..."
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && send()}
          />
          <Button size="icon" onClick={send} aria-label="Send message">
            <Send className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}