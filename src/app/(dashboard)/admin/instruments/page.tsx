"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Music } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function AdminInstrumentsPage() {
  const { instruments } = useAcademyData();
  const [list, setList] = React.useState(instruments);
  const [name, setName] = React.useState("");

  const add = () => {
    if (!name.trim()) return;
    setList((prev) => [...prev, { id: `inst-${Date.now()}`, name: name.trim(), icon: "Music", color: "#8d6bf6" }]);
    setName("");
    toast.success("Instrument added");
  };

  return (
    <div>
      <PageHeader title="Instruments" subtitle="Instruments taught at the academy." />

      <div className="mb-6 flex max-w-md gap-2">
        <Input placeholder="New instrument name..." value={name} onChange={(e) => setName(e.target.value)} onKeyDown={(e) => e.key === "Enter" && add()} />
        <Button onClick={add}>Add</Button>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {list.map((inst, i) => (
          <motion.div
            key={inst.id}
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.04 }}
            whileHover={{ y: -3 }}
            className="flex items-center gap-4 rounded-3xl border bg-card p-5 shadow-card"
          >
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl" style={{ backgroundColor: `${inst.color}22`, color: inst.color }}>
              <Music className="h-5 w-5" />
            </div>
            <div>
              <p className="font-semibold">{inst.name}</p>
              <p className="text-xs text-muted-foreground">
                {inst.id === "inst-6" || inst.id === "inst-7" ? "In use" : "In use"} � {inst.name}
              </p>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}