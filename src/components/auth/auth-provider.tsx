"use client";

import * as React from "react";
import { useRouter } from "next/navigation";

import { createClient, isSupabaseConfigured } from "@/lib/supabase/client";
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

  const isSupabase = isSupabaseConfigured;

  React.useEffect(() => {
    if (isSupabaseConfigured) {
      const supabase = createClient();
      supabase.auth.getSession().then(({ data }) => {
        if (data.session) {
          setUser({
            id: data.session.user.id,
            email: data.session.user.email ?? "",
            full_name: data.session.user.user_metadata?.full_name ?? "Student",
            role: (data.session.user.user_metadata?.role as Role) ?? "student",
            avatar_url: data.session.user.user_metadata?.avatar_url ?? null,
          });
        }
        setIsLoading(false);
      });
      return;
    }

    const raw = localStorage.getItem(DEMO_KEY);
    if (raw) {
      try {
        setUser(JSON.parse(raw));
      } catch {
        localStorage.removeItem(DEMO_KEY);
      }
    }
    setIsLoading(false);
  }, [isSupabase]);

  const loginDemo = (role: Role) => {
    const pool = demoProfiles[role];
    const profile = pool[0];
    localStorage.setItem(DEMO_KEY, JSON.stringify(profile));
    setUser(profile);
    router.push(`/${role === "admin" ? "admin" : `${role}`}`);
  };

  const loginSupabase = async (email: string, password: string) => {
    const supabase = createClient();
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return { error: error.message };
    const role = (data.user.user_metadata?.role as Role) ?? "student";
    setUser({
      id: data.user.id,
      email: data.user.email ?? "",
      full_name: data.user.user_metadata?.full_name ?? "Student",
      role,
      avatar_url: data.user.user_metadata?.avatar_url ?? null,
    });
    router.push(`/${role}`);
    return {};
  };

  const logout = async () => {
    if (isSupabaseConfigured) {
      const supabase = createClient();
      await supabase.auth.signOut();
    }
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
        isSupabase,
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
