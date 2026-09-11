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

export default function ParentProfilePage() {
  const { user, logout } = useAuth();
  const [name, setName] = React.useState(user?.full_name ?? "Rohan Sharma");
  const [childName, setChildName] = React.useState("Aarav Sharma");
  const [email] = React.useState(user?.email ?? "parent@maestro.app");

  return (
    <div>
      <PageHeader title="Profile" subtitle="Your guardian account." />
      <div className="mx-auto max-w-2xl space-y-6">
        <div className="flex items-center gap-5 rounded-3xl border bg-card p-6 shadow-card">
          <Avatar name={name} size="xl" />
          <div className="flex-1">
            <p className="text-lg font-bold">{name}</p>
            <p className="text-sm text-muted-foreground">{email}</p>
            <p className="mt-1 text-xs text-muted-foreground">Guardian of {childName}</p>
          </div>
          <Button variant="outline" size="sm" onClick={logout}><LogOut className="h-4 w-4" /> Sign out</Button>
        </div>
        <div className="space-y-4 rounded-3xl border bg-card p-6 shadow-card">
          <h2 className="text-sm font-semibold">Personal information</h2>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Full name</Label>
              <Input id="name" value={name} onChange={(e) => setName(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="child">Child</Label>
              <Input id="child" value={childName} onChange={(e) => setChildName(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" value={email} disabled />
            </div>
            <Button onClick={() => toast.success("Profile updated")}><Save className="h-4 w-4" /> Save changes</Button>
          </div>
        </div>
      </div>
    </div>
  );
}