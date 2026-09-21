import type { Metadata } from "next";

import { WebShell } from "@/components/dashboard/web-shell";
import { TokenAuthProvider } from "@/lib/auth/token-auth";

export const metadata: Metadata = {
  title: "Swar Mangal",
};

export default function StaffLayout({ children }: { children: React.ReactNode }) {
  return (
    <TokenAuthProvider>
      <WebShell role="OPS_USER">{children}</WebShell>
    </TokenAuthProvider>
  );
}