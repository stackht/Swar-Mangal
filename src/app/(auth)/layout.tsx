import type { Metadata } from "next";

import { AuthProvider } from "@/components/auth/auth-provider";
import { CommandShell } from "@/components/command/command-shell";
import { TokenAuthProvider } from "@/lib/auth/token-auth";

export const metadata: Metadata = {
  title: "Account | Swar Mangal",
};

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <TokenAuthProvider>
        <CommandShell>{children}</CommandShell>
      </TokenAuthProvider>
    </AuthProvider>
  );
}