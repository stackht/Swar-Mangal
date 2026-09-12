"use client";

import { motion } from "framer-motion";
import { GraduationCap, Mail, Phone } from "lucide-react";

import { PageHeader } from "@/components/dashboard/page-header";
import { Avatar } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function AdminTeachersPage() {
  const { teachers } = useAcademyData();
  return (
    <div>
      <PageHeader
        title="Teachers"
        subtitle={`${teachers.length} faculty members`}
        actions={<Button onClick={() => toast.success("Invite teacher flow opened")}><GraduationCap className="h-4 w-4" /> Invite teacher</Button>}
      />

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {teachers.map((t, i) => (
          <motion.div
            key={t.id}
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.05 }}
            whileHover={{ y: -3 }}
            className="rounded-3xl border bg-card p-5 shadow-card"
          >
            <div className="flex items-center gap-3">
              <Avatar name={t.full_name} size="lg" />
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold">{t.full_name}</p>
                <p className="text-xs text-muted-foreground">{t.instrument}</p>
              </div>
              <Badge variant="mint">Ã¢Ëœâ€¦ {t.rating}</Badge>
            </div>
            <div className="mt-4 space-y-1.5 text-xs text-muted-foreground">
              <p className="flex items-center gap-2"><Mail className="h-3.5 w-3.5" /> {t.email}</p>
              <p className="flex items-center gap-2"><Phone className="h-3.5 w-3.5" /> +1 (555) 000-{String(1000 + i).slice(-4)}</p>
            </div>
            <div className="mt-4 flex gap-2">
              <Button size="sm" variant="secondary" className="flex-1" onClick={() => toast.success(`Schedule for ${t.full_name}`)}>Schedule</Button>
              <Button size="sm" variant="outline" className="flex-1" onClick={() => toast.success("Message sent")}>Message</Button>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}