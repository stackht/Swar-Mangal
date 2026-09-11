"use client";

import { PageHeader } from "@/components/dashboard/page-header";
import { MessagesView } from "@/components/dashboard/messages-view";

export default function StudentMessagesPage() {
  return (
    <div>
      <PageHeader title="Messages" subtitle="Talk with your teachers." />
      <MessagesView currentUserId="s1" currentName="Aarav Sharma" />
    </div>
  );
}