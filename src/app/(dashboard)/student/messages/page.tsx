"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { MessagesView } from "@/components/dashboard/messages-view";
import { useAcademyData } from "@/hooks/use-academy-data";

export default function StudentMessagesPage() {
  const { students, currentStudentId } = useAcademyData();
  const me = students.find((s) => s.id === currentStudentId) ?? students[0];
  return (
    <div>
      <PageHeader title="Messages" subtitle="Talk with your teachers." />
      <MessagesView currentUserId={me?.id ?? "s1"} currentName={me?.full_name ?? "Aarav Sharma"} />
    </div>
  );
}