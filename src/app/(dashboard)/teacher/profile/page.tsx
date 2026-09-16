"use client";

import * as React from "react";
import { LogOut, Save } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { useAuth } from "@/components/auth/auth-provider";

import { useAcademyData } from "@/hooks/use-academy-data";

export default function TeacherProfilePage() {
  const { teachers } = useAcademyData();
  const { user, logout } = useAuth();
  const t = teachers[0];
  const [name, setName] = React.useState(user?.full_name ?? t.full_name);
  const [email] = React.useState(user?.email ?? t.email);
  const [phone, setPhone] = React.useState("");
  const [bio, setBio] = React.useState("Piano pedagogue with 8 years of teaching experience.");

  return (
    <div>
      <PageHeader title="Profile" subtitle="Your teacher profile." />

      <div className="mx-auto max-w-2xl space-y-6">
        <div className="flex items-center gap-5 rounded-3xl border bg-card p-6 shadow-card">
          <Avatar name={name} size="xl" />
          <div className="flex-1">
            <p className="text-lg font-bold">{name}</p>
            <p className="text-sm text-muted-foreground">{email}</p>
            <div className="mt-2 flex gap-2">
              <Badge variant="lavender">{t.instrument}</Badge>
              <Badge variant="mint">{t.rating}</Badge>
            </div>
          </div>
          <Button variant="outline" size="sm" onClick={logout}><LogOut className="h-4 w-4" /> Sign out</Button>
        </div>

        <div className="space-y-4 rounded-3xl border bg-card p-6 shadow-card">
          <h2 className="text-sm font-semibold">About</h2>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Full name</Label>
              <Input id="name" value={name} onChange={(e) => setName(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" value={email} disabled />
            </div>
            <div className="space-y-2">
              <Label htmlFor="phone">Phone</Label>
              <Input id="phone" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+1 (555) 000-0000" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="bio">Bio</Label>
              <Input id="bio" value={bio} onChange={(e) => setBio(e.target.value)} />
            </div>
            <Button onClick={() => toast.success("Profile updated")}><Save className="h-4 w-4" /> Save changes</Button>
          </div>
        </div>
      </div>
    </div>
  );
}