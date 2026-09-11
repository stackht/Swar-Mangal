import { RequireRole } from "@/components/auth/require-role";

export default function StudentLayout({ children }: { children: React.ReactNode }) {
  return <RequireRole role="student">{children}</RequireRole>;
}
