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
