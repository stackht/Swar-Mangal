// Payout settlement maths. Pure module (no runtime imports) so
// backend-tests can load it directly.

export type PayoutStatus = "UNPAID" | "PARTIAL" | "PAID" | "OVERPAID" | "NOTHING_DUE";

/** Money rounded to paise, avoiding 0.1 + 0.2 style drift. */
export const money = (v: number) => Math.round((Number.isFinite(v) ? v : 0) * 100) / 100;

/** Anything within a paisa counts as settled. */
const EPSILON = 0.005;

export function payoutStatus(payable: number, paid: number): PayoutStatus {
  const due = money(payable);
  const done = money(paid);
  if (done > due + EPSILON) return "OVERPAID";
  if (due <= EPSILON) return done > EPSILON ? "OVERPAID" : "NOTHING_DUE";
  if (done <= EPSILON) return "UNPAID";
  if (done >= due - EPSILON) return "PAID";
  return "PARTIAL";
}

/** What is still owed; never negative, even when overpaid. */
export function payoutBalance(payable: number, paid: number): number {
  return money(Math.max(0, money(payable) - money(paid)));
}

/** A service month is YYYY-MM. */
export function isServiceMonth(v: string): boolean {
  return /^\d{4}-(0[1-9]|1[0-2])$/.test(v);
}
