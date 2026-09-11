"use client";

import * as React from "react";
import { LogOut, Save } from "lucide-react";
import { toast } from "sonner";

import { PageHeader } from "@/components/dashboard/page-header";
import { Avatar } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAuth } from "@/components/auth/auth-provider";
import { Badge } from "@/components/ui/badge";

import { students } from "@/lib/data/demo";

export default function StudentProfilePage() {
  const { user, logout } = useAuth();
  const profile = students[0];
  const [name, setName] = React.useState(user?.full_name ?? profile.full_name);
  const [email] = React.useState(user?.email ?? profile.email);
  const [phone, setPhone] = React.useState("");

  return (
    <div>
      <PageHeader title="Profile" subtitle="Your account details." />

      <div className="mx-auto max-w-2xl space-y-6">
        <div className="flex items-center gap-5 rounded-3xl border bg-card p-6 shadow-card">
          <Avatar name={name} size="xl" />
          <div className="flex-1">
            <p className="text-lg font-bold">{name}</p>
            <p className="text-sm text-muted-foreground">{email}</p>
            <div className="mt-2 flex gap-2">
              <Badge variant="lavender">{profile.instrument}</Badge>
              <Badge variant="secondary">{profile.level}</Badge>
            </div>
          </div>
          <Button variant="outline" size="sm" onClick={logout}>
            <LogOut className="h-4 w-4" /> Sign out
          </Button>
        </div>

        <div className="space-y-4 rounded-3xl border bg-card p-6 shadow-card">
          <h2 className="text-sm font-semibold">Personal information</h2>
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
            <Button onClick={() => toast.success("Profile updated")}>
              <Save className="h-4 w-4" /> Save changes
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}