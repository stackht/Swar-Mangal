// Indian mobile numbers -> WhatsApp JIDs. Pure module (no runtime imports).

export type PhoneResult =
  | { ok: true; e164: string; jid: string; masked: string }
  | { ok: false; code: "NO_PHONE" | "NOT_A_MOBILE"; masked: string };

/** Show enough to recognise a number without exposing it: 98••••1223. */
export function maskPhone(raw: string): string {
  const digits = String(raw ?? "").replace(/\D/g, "");
  if (digits.length < 6) return digits ? "••••" : "";
  return `${digits.slice(0, 2)}••••${digits.slice(-4)}`;
}

/**
 * Normalise a stored phone to 91XXXXXXXXXX. Accepts the forms that appear in
 * the data: "9820011223", "09820011223", "+91 98200 11223", "919820011223".
 * Anything that is not a 10-digit Indian mobile (starting 6-9) is refused
 * rather than guessed at — a wrong guess messages a stranger.
 */
export function normalizeIndianMobile(raw: unknown): PhoneResult {
  const text = raw == null ? "" : String(raw);
  const masked = maskPhone(text);
  let digits = text.replace(/\D/g, "");
  if (!digits) return { ok: false, code: "NO_PHONE", masked };

  if (digits.length === 11 && digits.startsWith("0")) digits = digits.slice(1);
  if (digits.length === 13 && digits.startsWith("091")) digits = digits.slice(1);
  if (digits.length === 10) digits = `91${digits}`;

  if (!/^91[6-9]\d{9}$/.test(digits)) return { ok: false, code: "NOT_A_MOBILE", masked };
  return { ok: true, e164: digits, jid: `${digits}@s.whatsapp.net`, masked: maskPhone(digits.slice(2)) };
}

/** Parse a comma-separated allow-list (WA_ALLOWED_NUMBERS) into 91XXXXXXXXXX form. */
export function parseAllowList(raw: string | undefined): Set<string> {
  const out = new Set<string>();
  for (const part of String(raw ?? "").split(",")) {
    const r = normalizeIndianMobile(part);
    if (r.ok) out.add(r.e164);
  }
  return out;
}
