"use client";

import * as React from "react";
import { useRouter } from "next/navigation";

import { teachers, students } from "@/lib/data/demo";
import type { Profile, Role } from "@/types";

const DEMO_KEY = "maestro-demo-user";

export interface DemoUser extends Profile {
  instrument?: string;
  level?: string;
}

interface AuthContextValue {
  user: DemoUser | null;
  role: Role | null;
  isLoading: boolean;
  isSupabase: boolean;
  loginDemo: (role: Role) => void;
  loginSupabase: (email: string, password: string) => Promise<{ error?: string }>;
  logout: () => Promise<void>;
  refresh: () => void;
}

const AuthContext = React.createContext<AuthContextValue | undefined>(undefined);

const demoProfiles: Record<Role, DemoUser[]> = {
  admin: [
    {
      id: "admin",
      email: "admin@maestro.app",
      full_name: "Marcus Reed",
      role: "admin",
      avatar_url: null,
    },
  ],
  teacher: teachers.map((t) => ({
    ...t,
    role: "teacher" as Role,
  })),
  student: students.map((s) => ({
    ...s,
    role: "student" as Role,
  })),
  parent: [
    {
      id: "parent",
      email: "parent@maestro.app",
      full_name: "Rohan Sharma",
      role: "parent",
      avatar_url: null,
    },
  ],
};

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [user, setUser] = React.useState<DemoUser | null>(null);
  const [isLoading, setIsLoading] = React.useState(true);

  React.useEffect(() => {
    fetch("/api/auth/me", { cache: "no-store" })
      .then((r) => r.json())
      .then(({ user: live }) => {
        if (live) {
          setUser({
            id: live.id,
            email: live.email,
            full_name: live.full_name ?? "User",
            role: live.role,
            avatar_url: null,
          });
        }
      })
      .catch(() => {})
      .finally(() => {
        const raw = localStorage.getItem(DEMO_KEY);
        if (raw && !user) {
          try {
            setUser(JSON.parse(raw));
          } catch {
            localStorage.removeItem(DEMO_KEY);
          }
        }
        setIsLoading(false);
      });

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loginDemo = (role: Role) => {
    const pool = demoProfiles[role];
    const profile = pool[0];
    localStorage.setItem(DEMO_KEY, JSON.stringify(profile));
    setUser(profile);
    router.push(`/${role === "admin" ? "admin" : `${role}`}`);
  };

  const loginSupabase = async (email: string, password: string) => {
    const res = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    const json = await res.json();
    if (!res.ok) return { error: json.error ?? "Invalid credentials" };
    const live = json.user;
    setUser({
      id: live.id,
      email: live.email,
      full_name: live.full_name ?? "User",
      role: live.role,
      avatar_url: null,
    });
    router.push(`/${live.role}`);
    return {};
  };

  const logout = async () => {
    try {
      await fetch("/api/auth/me", { method: "POST" });
    } catch {}
    setUser(null);
    localStorage.removeItem(DEMO_KEY);
    router.push("/login");
  };

  const refresh = () => router.refresh();

  return (
    <AuthContext.Provider
      value={{
        user,
        role: user?.role ?? null,
        isLoading,
        isSupabase: true,
        loginDemo,
        loginSupabase,
        logout,
        refresh,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = React.useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}