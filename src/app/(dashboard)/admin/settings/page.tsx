"use client";

import * as React from "react";
import { Moon, Save, Sun } from "lucide-react";
import { useTheme } from "next-themes";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils/cn";

export default function AdminSettingsPage() {
  const { theme, setTheme } = useTheme();
  const [academyName, setAcademyName] = React.useState("Swar Mangal Music Academy");
  const [address, setAddress] = React.useState("Studio A, 42 Harmony Lane");
  const [email, setEmail] = React.useState("hello@maestro.app");

  const modes = [
    { key: "light", label: "Light", icon: Sun },
    { key: "dark", label: "Dark", icon: Moon },
    { key: "system", label: "System", icon: Sun },
  ] as const;

  return (
    <div>
      <PageHeader title="Settings" subtitle="Academy preferences." />

      <div className="space-y-6">
        <Card>
          <CardContent className="p-6">
            <h2 className="text-sm font-semibold">Academy details</h2>
            <div className="mt-4 space-y-4 max-w-md">
              <div className="space-y-2">
                <Label htmlFor="an">Academy name</Label>
                <Input id="an" value={academyName} onChange={(e) => setAcademyName(e.target.value)} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="addr">Address</Label>
                <Input id="addr" value={address} onChange={(e) => setAddress(e.target.value)} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="ae">Contact email</Label>
                <Input id="ae" value={email} onChange={(e) => setEmail(e.target.value)} />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <h2 className="text-sm font-semibold">Appearance</h2>
            <div className="mt-4 flex gap-2">
              {modes.map((m) => (
                <button
                  key={m.key}
                  onClick={() => setTheme(m.key)}
                  className={cn(
                    "flex items-center gap-2 rounded-2xl border px-4 py-2.5 text-sm font-medium transition-all",
                    theme === m.key ? "border-transparent bg-primary text-primary-foreground shadow-soft" : "bg-card text-muted-foreground hover:text-foreground",
                  )}
                >
                  <m.icon className="h-4 w-4" /> {m.label}
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <h2 className="text-sm font-semibold">Announcement settings</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Email digests for announcements are{" "}
              <button className="font-medium text-primary" onClick={() => toast.success("Digest settings toggled")}>enabled</button>.
            </p>
          </CardContent>
        </Card>

        <Button onClick={() => toast.success("Settings saved")}><Save className="h-4 w-4" /> Save settings</Button>
      </div>
    </div>
  );
}