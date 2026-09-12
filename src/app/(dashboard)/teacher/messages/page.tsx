"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { MessagesView } from "@/components/dashboard/messages-view";
import { useAcademyData } from "@/hooks/use-academy-data";

export default function TeacherMessagesPage() {
  const { teachers, currentTeacherId } = useAcademyData();
  const me = teachers.find((t) => t.id === currentTeacherId) ?? teachers[0];
  return (
    <div>
      <PageHeader title="Messages" subtitle="Talk with your students." />
      <MessagesView currentUserId={me?.id ?? "t1"} currentName={me?.full_name ?? "Sarah Mitchell"} />
    </div>
  );
}