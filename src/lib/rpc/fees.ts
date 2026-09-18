// ============================================================
// FEE CYCLES AND DUE DATES
//
// Every figure here comes from data stored per student (next_due_date,
// fee_cycle_months, ...). Where a student has no due date the state is
// UNKNOWN — the apps show "not set" rather than a made-up number.
//
// Pure module (no runtime imports) so backend-tests can load it directly.
// ============================================================

export type FeeState = "PAID" | "DUE_SOON" | "DUE_TODAY" | "OVERDUE" | "UNKNOWN" | "INACTIVE";

/** Days before the due date that a fee starts showing as "due soon". */
export const DEFAULT_ADVANCE_DAYS = 3;

const NOT_CHASED = new Set(["LEFT", "INACTIVE", "DUPLICATE", "TEST"]);

const DAY_MS = 86400000;
const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

/** Today in the academy's timezone (IST), as YYYY-MM-DD. */
export function todayIso(now: Date = new Date()): string {
  return new Date(now.getTime() + IST_OFFSET_MS).toISOString().slice(0, 10);
}

function parseIso(date: string): number | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return null;
  const ms = Date.parse(`${date}T00:00:00Z`);
  return Number.isNaN(ms) ? null : ms;
}

/** Whole days from today to the due date: negative when overdue. */
export function daysUntil(dueDate: string, today: string): number | null {
  const due = parseIso(dueDate);
  const now = parseIso(today);
  if (due == null || now == null) return null;
  return Math.round((due - now) / DAY_MS);
}

/**
 * Fee state for one student. `status` is the enrolment status: a student who
 * has left is never chased for fees.
 */
export function feeState(
  dueDate: string | null | undefined,
  today: string,
  opts: { status?: string; advanceDays?: number } = {},
): FeeState {
  // Left, duplicated and test records are not real enrolments to chase.
  const status = (opts.status ?? "").toUpperCase();
  if (NOT_CHASED.has(status)) return "INACTIVE";
  const advance = opts.advanceDays ?? DEFAULT_ADVANCE_DAYS;
  if (!dueDate) return "UNKNOWN";
  const days = daysUntil(dueDate, today);
  if (days == null) return "UNKNOWN";
  if (days < 0) return "OVERDUE";
  if (days === 0) return "DUE_TODAY";
  if (days <= advance) return "DUE_SOON";
  return "PAID";
}

/** Add whole months, clamping to the end of a shorter month (31 Jan + 1m = 28 Feb). */
export function addMonths(date: string, months: number): string {
  const ms = parseIso(date);
  if (ms == null) return date;
  const d = new Date(ms);
  const day = d.getUTCDate();
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() + months);
  const lastDay = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
  d.setUTCDate(Math.min(day, lastDay));
  return d.toISOString().slice(0, 10);
}

export interface CycleAdvance {
  cycleStart: string;
  cycleEnd: string;
  nextDueDate: string;
}

/**
 * Move a student's fee cycle on after a payment. The new cycle starts at the
 * old due date when that is still current, otherwise at the payment date —
 * so a late payment does not keep the student permanently overdue, and an
 * early payment does not shorten the cycle they already paid for.
 */
export function advanceCycle(
  currentDueDate: string | null | undefined,
  paidOn: string,
  cycleMonths: number | null | undefined,
): CycleAdvance {
  const months = cycleMonths && cycleMonths > 0 && cycleMonths <= 36 ? cycleMonths : 1;
  const due = currentDueDate && parseIso(currentDueDate) != null ? currentDueDate : null;
  const start = due && (daysUntil(due, paidOn) ?? -1) >= 0 ? due : paidOn;
  const end = addMonths(start, months);
  return { cycleStart: start, cycleEnd: end, nextDueDate: end };
}

/**
 * Split a total into `count` instalment amounts that sum to EXACTLY the
 * total (never a paisa short or over) — the last instalment absorbs the
 * rounding remainder instead of it silently disappearing.
 */
export function splitInstalments(total: number, count: number): number[] {
  if (count <= 0) return [];
  const base = Math.floor((total / count) * 100) / 100;
  const amounts: number[] = [];
  let running = 0;
  for (let i = 1; i <= count; i++) {
    const amount = i === count ? Math.round((total - running) * 100) / 100 : base;
    amounts.push(amount);
    running += amount;
  }
  return amounts;
}

// ---------------------------------------------------------------- plans

export interface FeePlan {
  name: string;
  /** Length of one paid cycle in months. */
  months: number;
  /** Fee for one cycle in rupees, when the plan fixes it. */
  amount: number | null;
}

/**
 * The academy's plans, owned by the SERVER (brief §0.4: the client never
 * decides money). The app's picker shows these same four.
 */
export const PLAN_CATALOG: FeePlan[] = [
  { name: "Plan 1", months: 1, amount: 2500 },
  { name: "Plan 2", months: 1, amount: 3600 },
  { name: "Plan 3", months: 3, amount: 6500 },
  { name: "Plan 4", months: 3, amount: 9500 },
];

/**
 * "Plan 3", "Plan 3 · 1 session/week…", "3 Months", "Monthly", "Yearly" ->
 * a plan. Unknown text returns null rather than a guessed cycle.
 */
export function resolvePlan(raw: unknown): FeePlan | null {
  const text = raw == null ? "" : String(raw).trim();
  if (!text) return null;
  const upper = text.toUpperCase();
  const planMatch = /^PLAN\s*([1-4])\b/.exec(upper);
  if (planMatch) return PLAN_CATALOG[Number(planMatch[1]) - 1];
  if (upper === "MONTHLY" || upper === "1 MONTH" || upper === "1M") return { name: "Monthly", months: 1, amount: null };
  if (upper === "YEARLY" || upper === "12 MONTHS" || upper === "12M") return { name: "Yearly", months: 12, amount: null };
  const months = /^(\d{1,2})\s*(M|MONTH|MONTHS)$/.exec(upper);
  if (months && Number(months[1]) >= 1 && Number(months[1]) <= 36) {
    return { name: `${Number(months[1])} Months`, months: Number(months[1]), amount: null };
  }
  return null;
}

/**
 * Money arriving from the app. The app sends integer PAISE (brief §5.7);
 * older screens send rupees as `amount`. Returns rupees, or 0 when absent,
 * non-numeric or not a whole number of paise.
 */
export function amountRupees(arg: Record<string, unknown>): number {
  const paise = arg["amountPaise"];
  if (paise !== undefined && paise !== null && String(paise).trim() !== "") {
    const p = Number(paise);
    return Number.isInteger(p) && p > 0 ? p / 100 : 0;
  }
  const rupees = Number(String(arg["amount"] ?? "").replace(/[^\d.]/g, ""));
  return Number.isFinite(rupees) && rupees > 0 ? Math.round(rupees * 100) / 100 : 0;
}

/** GMC/KMC and branch names -> branch; blank when nothing usable was sent. */
export function branchFromClient(arg: Record<string, unknown>): string {
  const code = String(arg["classCode"] ?? "").trim().toUpperCase();
  if (code === "GMC") return "GOREGAON";
  if (code === "KMC") return "KANDIVALI";
  const b = String(arg["branch"] ?? arg["location"] ?? "").trim().toUpperCase();
  if (b.includes("GOR")) return "GOREGAON";
  if (b.includes("KAN")) return "KANDIVALI";
  return "";
}

/**
 * Owner rule: every fee payment carries a UTR (bank/UPI reference) or a
 * physical receipt-book number — never neither. Returns the refusal text, or
 * null when the rule is met.
 */
export function referenceRuleViolation(reference: string, receiptBookNo: string): string | null {
  if (reference.trim() || receiptBookNo.trim()) return null;
  return "Enter the UTR / transaction reference, or the receipt-book number for cash. A fee payment cannot have neither.";
}
