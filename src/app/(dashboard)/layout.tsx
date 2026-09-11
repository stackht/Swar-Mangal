import type { Metadata } from "next";

import { AuthProvider } from "@/components/auth/auth-provider";
import { AppShell } from "@/components/dashboard/app-shell";

export const metadata: Metadata = {
  title: {
    default: "Swar Mangal",
    template: "%s | Swar Mangal",
  },
};

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <AppShell>{children}</AppShell>
    </AuthProvider>
  );
}
