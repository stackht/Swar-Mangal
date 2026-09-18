import { test } from "node:test";
import assert from "node:assert/strict";

import {
  generateOtp,
  hashOtp,
  normalizeEmail,
  isValidEmail,
  OTP_TTL_MINUTES,
  MAX_OTP_ATTEMPTS,
  OTP_RESEND_COOLDOWN_SECONDS,
} from "../src/lib/email/otp.ts";

test("generateOtp is always six ASCII digits", () => {
  for (let i = 0; i < 50; i++) {
    const code = generateOtp();
    assert.equal(code.length, 6, code);
    assert.match(code, /^\d{6}$/, code);
  }
});

test("hashOtp is deterministic and never stores the code itself", () => {
  const a = hashOtp("123456");
  const b = hashOtp("123456");
  const c = hashOtp("654321");
  assert.equal(a, b);
  assert.notEqual(a, c);
  assert.notEqual(a, "123456");
});

test("normalizeEmail trims and lowercases", () => {
  assert.equal(normalizeEmail("  Latika@Example.COM  "), "latika@example.com");
  assert.equal(normalizeEmail(null), "");
  assert.equal(normalizeEmail(undefined), "");
});

test("isValidEmail rejects obviously bad input", () => {
  assert.equal(isValidEmail("latika@example.com"), true);
  assert.equal(isValidEmail("not-an-email"), false);
  assert.equal(isValidEmail("missing@domain"), false);
  assert.equal(isValidEmail(""), false);
});

test("OTP policy constants are sane", () => {
  assert.equal(OTP_TTL_MINUTES, 10);
  assert.equal(MAX_OTP_ATTEMPTS, 5);
  assert.equal(OTP_RESEND_COOLDOWN_SECONDS, 60);
});
