import {
  LayoutDashboard,
  BookOpen,
  CalendarDays,
  Music,
  ListChecks,
  Library,
  TrendingUp,
  UserCheck,
  MessageSquare,
  Bell,
  User,
  CreditCard,
  Users,
  GraduationCap,
  Guitar,
  Megaphone,
  BarChart3,
  Settings,
  type LucideIcon,
} from "lucide-react";
import type { Role } from "@/types";

export interface NavItem {
  title: string;
  href: string;
  icon: LucideIcon;
}

export interface NavSection {
  label: string;
  items: NavItem[];
}

export const navByRole: Record<Role, NavSection[]> = {
  student: [
    {
      label: "",
      items: [
        { title: "Dashboard", href: "/student", icon: LayoutDashboard },
        { title: "My Classes", href: "/student/classes", icon: BookOpen },
        { title: "Schedule", href: "/student/schedule", icon: CalendarDays },
        { title: "Practice", href: "/student/practice", icon: Music },
        { title: "Assignments", href: "/student/assignments", icon: ListChecks },
        { title: "Library", href: "/student/library", icon: Library },
        { title: "Progress", href: "/student/progress", icon: TrendingUp },
        { title: "Attendance", href: "/student/attendance", icon: UserCheck },
        { title: "Messages", href: "/student/messages", icon: MessageSquare },
        { title: "Payments", href: "/student/payments", icon: CreditCard },
      ],
    },
    {
      label: "Account",
      items: [
        { title: "Notifications", href: "/student/notifications", icon: Bell },
        { title: "Profile", href: "/student/profile", icon: User },
      ],
    },
  ],
  teacher: [
    {
      label: "",
      items: [
        { title: "Dashboard", href: "/teacher", icon: LayoutDashboard },
        { title: "My Classes", href: "/teacher/classes", icon: BookOpen },
        { title: "Students", href: "/teacher/students", icon: Users },
        { title: "Schedule", href: "/teacher/schedule", icon: CalendarDays },
        { title: "Attendance", href: "/teacher/attendance", icon: UserCheck },
        { title: "Assignments", href: "/teacher/assignments", icon: ListChecks },
        { title: "Practice Tracking", href: "/teacher/practice", icon: Music },
        { title: "Learning Materials", href: "/teacher/library", icon: Library },
        { title: "Messages", href: "/teacher/messages", icon: MessageSquare },
      ],
    },
    {
      label: "Account",
      items: [
        { title: "Progress", href: "/teacher/progress", icon: TrendingUp },
        { title: "Notifications", href: "/teacher/notifications", icon: Bell },
        { title: "Profile", href: "/teacher/profile", icon: User },
      ],
    },
  ],
  admin: [
    {
      label: "",
      items: [
        { title: "Dashboard", href: "/admin", icon: LayoutDashboard },
        { title: "Students", href: "/admin/students", icon: Users },
        { title: "Teachers", href: "/admin/teachers", icon: GraduationCap },
        { title: "Courses", href: "/admin/courses", icon: BookOpen },
        { title: "Instruments", href: "/admin/instruments", icon: Guitar },
        { title: "Schedule", href: "/admin/schedule", icon: CalendarDays },
        { title: "Fees & Payments", href: "/admin/fees", icon: CreditCard },
        { title: "Announcements", href: "/admin/announcements", icon: Megaphone },
        { title: "Analytics", href: "/admin/analytics", icon: BarChart3 },
      ],
    },
    {
      label: "Manage",
      items: [
        { title: "Learning Materials", href: "/admin/library", icon: Library },
        { title: "Notifications", href: "/admin/notifications", icon: Bell },
        { title: "Settings", href: "/admin/settings", icon: Settings },
      ],
    },
  ],
  parent: [
    {
      label: "",
      items: [
        { title: "Dashboard", href: "/parent", icon: LayoutDashboard },
        { title: "Attendance", href: "/parent/attendance", icon: UserCheck },
        { title: "Progress", href: "/parent/progress", icon: TrendingUp },
        { title: "Messages", href: "/parent/messages", icon: MessageSquare },
      ],
    },
    {
      label: "Account",
      items: [
        { title: "Notifications", href: "/parent/notifications", icon: Bell },
        { title: "Profile", href: "/parent/profile", icon: User },
      ],
    },
  ],
};

export function mobileNav(role: Role): NavItem[] {
  const sections = navByRole[role];
  const items = sections.flatMap((s) => s.items);
  const byPath = new Map(items.map((i) => [i.href, i]));
  const pick = (key: string) =>
    byPath.get(key) ?? byPath.get(`/${role}`) ?? items[0];
  return [pick(`/${role}`), pick(`/${role}/classes`), pick(`/${role}/schedule`), pick(`/${role}/practice`), pick(`/${role}/messages`)];
}

export function getRoleHome(role: Role) {
  return `/${role}`;
}
