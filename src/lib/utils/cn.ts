import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: Date | string, options?: Intl.DateTimeFormatOptions) {
  return new Intl.DateTimeFormat("en-US", options).format(new Date(date));
}

export function formatTime(date: Date | string) {
  return new Intl.DateTimeFormat("en-US", {
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(date));
}

export function formatINR(n: number | string | null | undefined) {
  const num = typeof n === "number" ? n : Number(n ?? NaN);
  if (!Number.isFinite(num)) return "—";
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(num);
}

export function initials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .filter(Boolean)
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

/** Indian-rupee display helper: 1250 → ₹1,250. */
export function inr(n: number | string | null | undefined): string {
  const v = typeof n === "string" ? Number(n) : n;
  if (v == null || !Number.isFinite(v)) return "—";
  return `₹${v.toLocaleString("en-IN")}`;
}

/** "YYYY-MM-DD" (or ISO) → "21 Sep 2026". Timezone-safe against the UTC parse trap. */
export function fmtDate(s: string | null | undefined): string {
  if (!s) return "—";
  const [y, m, d] = s.slice(0, 10).split("-").map(Number);
  if (!y || !m || !d) return s;
  return new Intl.DateTimeFormat("en-IN", { day: "numeric", month: "short", year: "numeric" }).format(
    new Date(y, m - 1, d),
  );
}

/** Local-date string the backend expects, e.g. "2026-09-21". */
export function todayISO(): string {
  const n = new Date();
  const pad = (v: number) => String(v).padStart(2, "0");
  return `${n.getFullYear()}-${pad(n.getMonth() + 1)}-${pad(n.getDate())}`;
}

/** "YYYY-MM" for the current month. */
export function currentMonth(): string {
  const n = new Date();
  return `${n.getFullYear()}-${String(n.getMonth() + 1).padStart(2, "0")}`;
}

/** Shift a "YYYY-MM-DD" date by `months` (keeps the day, rolls the year). */
export function addMonths(s: string, months: number): string {
  const [y, m, d] = s.slice(0, 10).split("-").map(Number);
  const pad = (v: number) => String(v).padStart(2, "0");
  const date = new Date(y, m - 1 + months, 1);
  const maxDay = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(Math.min(d || 1, maxDay))}`;
}
