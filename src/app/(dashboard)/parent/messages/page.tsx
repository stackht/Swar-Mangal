"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { MessagesView } from "@/components/dashboard/messages-view";

export default function ParentMessagesPage() {
  return (
    <div>
      <PageHeader title="Messages" subtitle="Conversations with teachers and staff." />
      <p className="mb-4 rounded-2xl bg-secondary p-3 text-xs text-muted-foreground">
        You are shadowing conversations as {`Aarav Sharma's`} guardian.
      </p>
      <MessagesView currentUserId="s1" currentName="Aarav Sharma" />
    </div>
  );
}