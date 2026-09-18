// Pure OTP helpers — no DB, no network import — so backend-tests can load
// this directly, matching the fees.ts/rules.ts convention.
import { createHash, randomInt } from "crypto";

export const OTP_TTL_MINUTES = 10;
export const MAX_OTP_ATTEMPTS = 5;
export const OTP_RESEND_COOLDOWN_SECONDS = 60;

/** The one fixed founder identity (matches src/lib/rpc/auth.ts:42). Override for a different founder without a code change. */
export const FOUNDER_EMAIL = (process.env.FOUNDER_EMAIL || "sharvil87@gmail.com").trim().toLowerCase();

/** Six ASCII digits, zero-padded — never trust string concatenation of a random int for width. */
export function generateOtp(): string {
  return String(randomInt(0, 1_000_000)).padStart(6, "0");
}

/** Same hash-at-rest idiom as hashToken in auth.ts — the code itself is never stored. */
export function hashOtp(code: string): string {
  return createHash("sha256").update(code).digest("hex");
}

export function normalizeEmail(email: unknown): string {
  return String(email ?? "").trim().toLowerCase();
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
export function isValidEmail(email: string): boolean {
  return EMAIL_RE.test(email);
}
