import { test } from "node:test";
import assert from "node:assert/strict";

import { payoutStatus, payoutBalance, money, isServiceMonth } from "../src/lib/rpc/payouts.ts";

test("status reflects how much of the payable has been paid", () => {
  assert.equal(payoutStatus(3050, 0), "UNPAID");
  assert.equal(payoutStatus(3050, 1000), "PARTIAL");
  assert.equal(payoutStatus(3050, 3050), "PAID");
  assert.equal(payoutStatus(3050, 4000), "OVERPAID");
});

test("nothing earned is not the same as unpaid", () => {
  // A teacher with no collection this month should not sit in an UNPAID list.
  assert.equal(payoutStatus(0, 0), "NOTHING_DUE");
  assert.equal(payoutStatus(0, 500), "OVERPAID");
});

test("a paisa of float drift still counts as settled", () => {
  assert.equal(payoutStatus(0.1 + 0.2, 0.3), "PAID");
  assert.equal(payoutStatus(3050, 3049.999), "PAID");
  assert.equal(payoutStatus(3050, 3049.5), "PARTIAL");
});

test("balance never goes negative", () => {
  assert.equal(payoutBalance(3050, 1000), 2050);
  assert.equal(payoutBalance(3050, 3050), 0);
  assert.equal(payoutBalance(3050, 5000), 0);
});

test("part payments add up to settled", () => {
  const payable = 9500;
  let paid = 0;
  for (const part of [4000, 3000, 2500]) {
    paid += part;
    const status = payoutStatus(payable, paid);
    if (paid < payable) assert.equal(status, "PARTIAL");
  }
  assert.equal(paid, payable);
  assert.equal(payoutStatus(payable, paid), "PAID");
  assert.equal(payoutBalance(payable, paid), 0);
});

test("money rounds to paise", () => {
  assert.equal(money(3049.999), 3050);
  assert.equal(money(1234.567), 1234.57);
  assert.equal(money(Number.NaN), 0);
});

test("service month must be a real YYYY-MM", () => {
  assert.equal(isServiceMonth("2026-09"), true);
  assert.equal(isServiceMonth("2026-12"), true);
  assert.equal(isServiceMonth("2026-13"), false);
  assert.equal(isServiceMonth("2026-00"), false);
  assert.equal(isServiceMonth("2026-9"), false);
  assert.equal(isServiceMonth("September"), false);
  assert.equal(isServiceMonth(""), false);
});
