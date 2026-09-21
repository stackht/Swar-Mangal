"use client";

// Client-side token auth. The raw device token NEVER touches client JS —
// it lives only in the httpOnly sm_rpc_token cookie, set by /api/auth/token.
// This module manages the session state derived from the cookie.

import * as React from "react";

export type TokenRole = "FOUNDER_ADMIN" | "OPS_USER";

export interface TokenSession {
  role: TokenRole;
  email: string;
  name: string;
  branches: string[];
}

interface TokenAuthContextValue {
  session: TokenSession | null;
  isLoading: boolean;
  error: string | null;
  restore: () => Promise<void>;
  login: (token: string, endpoint?: "founder" | "staff") => Promise<boolean>;
  logout: () => Promise<void>;
  clearError: () => void;
}

const TokenAuthContext = React.createContext<TokenAuthContextValue | undefined>(undefined);

export function TokenAuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = React.useState<TokenSession | null>(null);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  const restore = React.useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/auth/token", { credentials: "include", cache: "no-store" });
      if (!res.ok) { setSession(null); return; }
      const data = await res.json();
      if (data.ok) {
        setSession({ role: data.role, email: data.email, name: data.name, branches: data.branches ?? [] });
      } else {
        setSession(null);
      }
    } catch {
      setSession(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const login = React.useCallback(async (token: string, endpoint?: "founder" | "staff"): Promise<boolean> => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/auth/token", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token, endpoint }),
      });
      const data = await res.json();
      if (!data.ok) {
        setError(data.error ?? "Login failed");
        setIsLoading(false);
        return false;
      }
      setSession({ role: data.role, email: data.email, name: data.name, branches: data.branches ?? [] });
      setIsLoading(false);
      return true;
    } catch {
      setError("Could not reach server. Check your connection.");
      setIsLoading(false);
      return false;
    }
  }, []);

  const logout = React.useCallback(async () => {
    try { await fetch("/api/auth/token", { method: "DELETE", credentials: "include" }); } catch {}
    setSession(null);
    setIsLoading(false);
    setError(null);
  }, []);

  const clearError = React.useCallback(() => setError(null), []);

  // Validate session on mount.
  React.useEffect(() => { restore(); }, [restore]);

  return (
    <TokenAuthContext.Provider value={{ session, isLoading, error, restore, login, logout, clearError }}>
      {children}
    </TokenAuthContext.Provider>
  );
}

export function useTokenAuth() {
  const ctx = React.useContext(TokenAuthContext);
  if (!ctx) throw new Error("useTokenAuth must be used within TokenAuthProvider");
  return ctx;
}
