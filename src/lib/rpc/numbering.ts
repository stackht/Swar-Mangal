// Document numbering helpers (pure; the counter itself lives in doc_counters).

/**
 * Indian financial year label (April–March) for a date, in IST.
 * 2026-04-01 → "26-27", 2026-03-31 → "25-26".
 */
export function financialYearLabel(date: Date = new Date()): string {
  const ist = new Date(date.getTime() + 5.5 * 60 * 60 * 1000);
  const y = ist.getUTCFullYear();
  const start = ist.getUTCMonth() >= 3 ? y : y - 1;
  const two = (n: number) => String(n % 100).padStart(2, "0");
  return `${two(start)}-${two(start + 1)}`;
}

/** SMR-26-27 + 7 → SMR-26-27-007 (grows past 3 digits naturally). */
export function formatDocNo(series: string, no: number): string {
  return `${series}-${String(no).padStart(3, "0")}`;
}

export const receiptSeries = (date?: Date) => `SMR-${financialYearLabel(date)}`;
export const schoolInvoiceSeries = (date?: Date) => `SMI-${financialYearLabel(date)}`;
