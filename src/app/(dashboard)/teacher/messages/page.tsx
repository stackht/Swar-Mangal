"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { MessagesView } from "@/components/dashboard/messages-view";

export default function TeacherMessagesPage() {
  return (
    <div>
      <PageHeader title="Messages" subtitle="Talk with your students." />
      <MessagesView currentUserId="t1" currentName="Sarah Mitchell" />
    </div>
  );
}