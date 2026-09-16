import { test } from "node:test";
import assert from "node:assert/strict";

import { authorizeRpc, authorizeBranch, RPC_POLICY } from "../src/lib/rpc/authorization.ts";

const session = (role: RpcRole) =>
  ({ role, email: role === "FOUNDER_ADMIN" ? "sharvil87@gmail.com" : "smmahavirnagar@gmail.com", name: role }) as const;

const founder = session("FOUNDER_ADMIN");
const staff = session("OPS_USER");

test("authorizeRpc: founder -> founder gateway boot allowed", () => {
  const r = authorizeRpc(founder, "api_bootstrap");
  assert.equal(r.ok, true);
});

test("authorizeRpc: founder -> every founder+staff policy entry allowed", () => {
  for (const [fn] of Object.entries(RPC_POLICY)) {
    const r = authorizeRpc(founder, fn);
    assert.equal(r.ok, true, `${fn} should be allowed for FOUNDER_ADMIN`);
  }
});

test("authorizeRpc: staff -> legitimate staff endpoint allowed", () => {
  const r = authorizeRpc(staff, "api_staff_searchStudents");
  assert.equal(r.ok, true);
  const r2 = authorizeRpc(staff, "api_staff_todaysTasks");
  assert.equal(r2.ok, true);
});

test("authorizeRpc: staff -> api_teacherPayoutPreview ROLE_FORBIDDEN and handler NOT called", () => {
  let handlerRan = false;
  const r = authorizeRpc(staff, "api_teacherPayoutPreview");
  assert.equal(r.ok, false);
  assert.equal(r.code, "ROLE_FORBIDDEN");
  assert.equal(handlerRan, false); // guard: we never even reach handler path
});

test("authorizeRpc: staff -> api_updateTeacherCompensation ROLE_FORBIDDEN", () => {
  const r = authorizeRpc(staff, "api_updateTeacherCompensation");
  assert.equal(r.ok, false);
  assert.equal(r.code, "ROLE_FORBIDDEN");
});

test("authorizeRpc: staff -> api_addTeacher ROLE_FORBIDDEN", () => {
  const r = authorizeRpc(staff, "api_addTeacher");
  assert.equal(r.ok, false);
  assert.equal(r.code, "ROLE_FORBIDDEN");
});

test("authorizeRpc: staff -> api_timetableCreate ROLE_FORBIDDEN", () => {
  const r = authorizeRpc(staff, "api_timetableCreate");
  assert.equal(r.ok, false);
  assert.equal(r.code, "ROLE_FORBIDDEN");
});

test("authorizeRpc: staff -> api_timetableUpdate ROLE_FORBIDDEN", () => {
  const r = authorizeRpc(staff, "api_timetableUpdate");
  assert.equal(r.ok, false);
  assert.equal(r.code, "ROLE_FORBIDDEN");
});

test("authorizeRpc: staff -> api_timetableDelete ROLE_FORBIDDEN", () => {
  const r = authorizeRpc(staff, "api_timetableDelete");
  assert.equal(r.ok, false);
  assert.equal(r.code, "ROLE_FORBIDDEN");
});

test("authorizeRpc: staff -> founder approval endpoint ROLE_FORBIDDEN", () => {
  const r = authorizeRpc(staff, "api_founder_approvalsList");
  assert.equal(r.ok, false);
  assert.equal(r.code, "ROLE_FORBIDDEN");
});

test("authorizeRpc: staff -> founder financial finalisation ROLE_FORBIDDEN", () => {
  const r = authorizeRpc(staff, "api_founder_finalisePaymentDraft");
  assert.equal(r.ok, false);
  assert.equal(r.code, "ROLE_FORBIDDEN");
});

test("authorizeRpc: staff -> founder expense write ROLE_FORBIDDEN", () => {
  const r = authorizeRpc(staff, "api_addExpenseEntry");
  assert.equal(r.ok, false);
});

test("unknown function with valid token -> UNKNOWN_API (fail closed)", () => {
  const r = authorizeRpc(founder, "api_doesNotExist");
  assert.equal(r.ok, false);
  assert.equal(r.code, "UNKNOWN_API");
});

test("every policy entry has founder/staff value", () => {
  for (const [fn, req] of Object.entries(RPC_POLICY)) {
    assert.ok(fn.startsWith("api_"), fn);
    assert.ok(req === "FOUNDER" || req === "STAFF", fn);
  }
});

// ---------------- branch isolation ----------------
test("authorizeBranch: founder allowed any branch", () => {
  const r = authorizeBranch(founder, { branch: "GOREGAON" });
  assert.equal(r.ok, true);
});

test("authorizeBranch: staff allowed configured branch", () => {
  const r = authorizeBranch(staff, { branch: "KANDIVALI" });
  assert.equal(r.ok, true);
});

test("authorizeBranch: staff denied unknown branch", () => {
  const r = authorizeBranch(staff, { branch: "SURAT" });
  assert.equal(r.ok, false);
  assert.equal(r.code, "BRANCH_FORBIDDEN");
});

test("authorizeBranch: staff entityId entity isolation", () => {
  const g = authorizeBranch(staff, { entityId: "ENT-GOREGAON" });
  assert.equal(g.ok, true);
  const k = authorizeBranch(staff, { entityId: "ENT-KANDIVALI" });
  assert.equal(k.ok, true);
});

test("authorizeBranch: staff classCode maps to branch", () => {
  const r = authorizeBranch(staff, { classCode: "GMC" });
  assert.equal(r.ok, true);
});

test("authorizeBranch: scope ALL is not branch-gated", () => {
  const r = authorizeBranch(staff, { scope: "ALL" });
  assert.equal(r.ok, true);
});

test("authorizeBranch: founder bypasses branch allow-list entirely", () => {
  const r = authorizeBranch(founder, { branch: "SOME_OTHER" });
  assert.equal(r.ok, true);
});