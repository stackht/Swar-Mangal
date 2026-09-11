import type { Metadata } from "next";

import { AuthProvider } from "@/components/auth/auth-provider";
import { CommandShell } from "@/components/command/command-shell";

export const metadata: Metadata = {
  title: "Account | Swar Mangal",
};

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <CommandShell>{children}</CommandShell>
    </AuthProvider>
  );
}