import { RequireRole } from "@/components/auth/require-role";

export default function ParentLayout({ children }: { children: React.ReactNode }) {
  return <RequireRole role="parent">{children}</RequireRole>;
}
