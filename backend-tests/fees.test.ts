import { test } from "node:test";
import assert from "node:assert/strict";

import { feeState, daysUntil, addMonths, advanceCycle, todayIso, DEFAULT_ADVANCE_DAYS } from "../src/lib/rpc/fees.ts";

const TODAY = "2026-09-16";

test("fee state follows the stored due date", () => {
  assert.equal(feeState("2026-09-10", TODAY), "OVERDUE");
  assert.equal(feeState("2026-09-15", TODAY), "OVERDUE");
  assert.equal(feeState("2026-09-16", TODAY), "DUE_TODAY");
  assert.equal(feeState("2026-09-17", TODAY), "DUE_SOON");
  assert.equal(feeState("2026-09-19", TODAY), "DUE_SOON"); // 3 days = advance window
  assert.equal(feeState("2026-09-20", TODAY), "PAID");
  assert.equal(feeState("2026-12-01", TODAY), "PAID");
});

test("a student with no recorded due date is UNKNOWN, never overdue", () => {
  // The old code called every active student OVERDUE.
  assert.equal(feeState(null, TODAY), "UNKNOWN");
  assert.equal(feeState("", TODAY), "UNKNOWN");
  assert.equal(feeState("not-a-date", TODAY), "UNKNOWN");
});

test("students who left are not chased", () => {
  assert.equal(feeState("2026-01-01", TODAY, { status: "LEFT" }), "INACTIVE");
  assert.equal(feeState(null, TODAY, { status: "LEFT" }), "INACTIVE");
  assert.equal(feeState("2026-01-01", TODAY, { status: "ACTIVE" }), "OVERDUE");
});

test("the advance window is configurable", () => {
  assert.equal(DEFAULT_ADVANCE_DAYS, 3);
  assert.equal(feeState("2026-09-23", TODAY, { advanceDays: 7 }), "DUE_SOON");
  assert.equal(feeState("2026-09-23", TODAY, { advanceDays: 3 }), "PAID");
});

test("daysUntil counts whole days in both directions", () => {
  assert.equal(daysUntil("2026-09-16", TODAY), 0);
  assert.equal(daysUntil("2026-09-26", TODAY), 10);
  assert.equal(daysUntil("2026-09-06", TODAY), -10);
  assert.equal(daysUntil("bad", TODAY), null);
});

test("addMonths clamps to the end of a shorter month", () => {
  assert.equal(addMonths("2026-01-31", 1), "2026-02-28");
  assert.equal(addMonths("2026-01-15", 3), "2026-04-15");
  assert.equal(addMonths("2026-12-15", 1), "2027-01-15");
  assert.equal(addMonths("2026-11-30", 3), "2027-02-28");
});

test("paying on time extends from the due date, so cycles do not drift", () => {
  const c = advanceCycle("2026-09-20", "2026-09-16", 1);
  assert.equal(c.cycleStart, "2026-09-20");
  assert.equal(c.nextDueDate, "2026-10-20");
});

test("paying late restarts from the payment date, not the missed due date", () => {
  const c = advanceCycle("2026-07-01", "2026-09-16", 1);
  assert.equal(c.cycleStart, "2026-09-16");
  assert.equal(c.nextDueDate, "2026-10-16");
  // and the student is no longer overdue afterwards
  assert.equal(feeState(c.nextDueDate, "2026-09-16"), "PAID");
});

test("a 3-month plan advances by three months", () => {
  assert.equal(advanceCycle("2026-09-16", "2026-09-16", 3).nextDueDate, "2026-12-16");
});

test("a missing or silly cycle length falls back to one month", () => {
  assert.equal(advanceCycle("2026-09-16", "2026-09-16", null).nextDueDate, "2026-10-16");
  assert.equal(advanceCycle("2026-09-16", "2026-09-16", 0).nextDueDate, "2026-10-16");
  assert.equal(advanceCycle("2026-09-16", "2026-09-16", 999).nextDueDate, "2026-10-16");
});

test("a first payment with no prior due date starts the cycle today", () => {
  const c = advanceCycle(null, "2026-09-16", 1);
  assert.equal(c.cycleStart, "2026-09-16");
  assert.equal(c.nextDueDate, "2026-10-16");
});

test("today is measured in IST, not UTC", () => {
  // 2026-09-16 20:00 UTC is already the 17th in Mumbai.
  assert.equal(todayIso(new Date("2026-09-16T20:00:00Z")), "2026-09-17");
  assert.equal(todayIso(new Date("2026-09-16T10:00:00Z")), "2026-09-16");
});

test("duplicate and test records are not chased either", () => {
  assert.equal(feeState("2026-01-01", TODAY, { status: "DUPLICATE" }), "INACTIVE");
  assert.equal(feeState("2026-01-01", TODAY, { status: "TEST" }), "INACTIVE");
});
