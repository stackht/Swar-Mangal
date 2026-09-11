import type { Metadata } from "next";

import { AuthProvider } from "@/components/auth/auth-provider";

export const metadata: Metadata = {
  title: "Account | Swar Mangal",
};

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return <AuthProvider>{children}</AuthProvider>;
}
