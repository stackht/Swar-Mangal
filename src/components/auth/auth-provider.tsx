"use client";

import * as React from "react";
import { useRouter } from "next/navigation";

import type { Profile, Role } from "@/types";

export interface SessionUser extends Profile {
  instrument?: string;
  level?: string;
}

interface AuthContextValue {
  user: SessionUser | null;
  role: Role | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<{ error?: string }>;
  logout: () => Promise<void>;
  refresh: () => void;
}

const AuthContext = React.createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [user, setUser] = React.useState<SessionUser | null>(null);
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
      .finally(() => setIsLoading(false));
  }, []);

  const login = async (email: string, password: string) => {
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
    router.push("/login");
  };

  const refresh = () => router.refresh();

  return (
    <AuthContext.Provider
      value={{
        user,
        role: user?.role ?? null,
        isLoading,
        login,
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