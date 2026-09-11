import { RequireRole } from "@/components/auth/require-role";

export default function TeacherLayout({ children }: { children: React.ReactNode }) {
  return <RequireRole role="teacher">{children}</RequireRole>;
}
