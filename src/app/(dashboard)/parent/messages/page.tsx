"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { MessagesView } from "@/components/dashboard/messages-view";
import { useAcademyData } from "@/hooks/use-academy-data";

export default function ParentMessagesPage() {
  const { students, currentStudentId } = useAcademyData();
  const child = students.find((s) => s.id === currentStudentId) ?? students[0];
  return (
    <div>
      <PageHeader title="Messages" subtitle="Conversations with teachers and staff." />
      <p className="mb-4 rounded-2xl bg-secondary p-3 text-xs text-muted-foreground">
        You are shadowing conversations as {`${child?.full_name ?? "your child"}'s`} guardian.
      </p>
      <MessagesView currentUserId={child?.id ?? "s1"} currentName={child?.full_name ?? "Aarav Sharma"} />
    </div>
  );
}