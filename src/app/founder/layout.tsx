import type { Metadata } from "next";

import { WebShell } from "@/components/dashboard/web-shell";
import { TokenAuthProvider } from "@/lib/auth/token-auth";

export const metadata: Metadata = {
  title: "Swar Mangal",
};

export default function FounderLayout({ children }: { children: React.ReactNode }) {
  return (
    <TokenAuthProvider>
      <WebShell role="FOUNDER_ADMIN">{children}</WebShell>
    </TokenAuthProvider>
  );
}