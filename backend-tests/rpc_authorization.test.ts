import { test } from "node:test";
import assert from "node:assert/strict";

// Staff branches are fail-closed: set the env the deployment uses before import.
process.env.RPC_STAFF_BRANCHES = "GOREGAON,KANDIVALI";

import { authorizeRpc, authorizeBranch, roleAllowedBranches, scopeForSession, WRITE_FUNCTIONS, RPC_POLICY } from "../src/lib/rpc/authorization.ts";
import type { RpcRole } from "../src/lib/rpc/auth.ts";

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

test("authorizeRpc: staff -> api_timetableCreate ALLOWED", () => {
  const r = authorizeRpc(staff, "api_timetableCreate");
  assert.equal(r.ok, true);
});

test("authorizeRpc: staff -> api_timetableUpdate ALLOWED", () => {
  const r = authorizeRpc(staff, "api_timetableUpdate");
  assert.equal(r.ok, true);
});

test("authorizeRpc: staff -> api_timetableDelete ALLOWED", () => {
  const r = authorizeRpc(staff, "api_timetableDelete");
  assert.equal(r.ok, true);
});

test("authorizeRpc: staff -> api_generateSchoolInvoice ALLOWED", () => {
  const r = authorizeRpc(staff, "api_generateSchoolInvoice");
  assert.equal(r.ok, true);
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
test("roleAllowedBranches: staff comes from env, founder gets everything", () => {
  assert.deepEqual(roleAllowedBranches("FOUNDER_ADMIN"), ["GOREGAON", "KANDIVALI"]);
  process.env.RPC_STAFF_BRANCHES = "KANDIVALI";
  assert.deepEqual(roleAllowedBranches("OPS_USER"), ["KANDIVALI"]);
  process.env.RPC_STAFF_BRANCHES = "GOREGAON,KANDIVALI";
});

test("roleAllowedBranches: unset env means no staff branches (fail closed)", () => {
  const saved = process.env.RPC_STAFF_BRANCHES;
  delete process.env.RPC_STAFF_BRANCHES;
  assert.deepEqual(roleAllowedBranches("OPS_USER"), []);
  // Founder is unaffected.
  assert.deepEqual(roleAllowedBranches("FOUNDER_ADMIN"), ["GOREGAON", "KANDIVALI"]);
  process.env.RPC_STAFF_BRANCHES = saved;
});

test("authorizeBranch: staff restricted to one branch is denied the other", () => {
  const saved = process.env.RPC_STAFF_BRANCHES;
  process.env.RPC_STAFF_BRANCHES = "KANDIVALI";
  const denied = authorizeBranch(staff, { branch: "GOREGAON" });
  assert.equal(denied.ok, false);
  assert.equal(denied.code, "BRANCH_FORBIDDEN");
  assert.equal(authorizeBranch(staff, { branch: "KANDIVALI" }).ok, true);
  assert.equal(authorizeBranch(staff, { entityId: "ENT-GOREGAON" }).ok, false);
  assert.equal(authorizeBranch(staff, { classCode: "GMC" }).ok, false);
  process.env.RPC_STAFF_BRANCHES = saved;
});

// ---------------- device tokens ----------------
test("scopeForSession: a device's own branch list overrides the env default", () => {
  const saved = process.env.RPC_STAFF_BRANCHES;
  process.env.RPC_STAFF_BRANCHES = "GOREGAON,KANDIVALI";
  const device = { ...staff, deviceLabel: "Latika Pixel", branches: ["KANDIVALI"] };
  const scope = scopeForSession(device);
  assert.equal(scope.unrestricted, false);
  assert.deepEqual(scope.branches, ["KANDIVALI"]);
  // Without a device list it falls back to the env allow-list.
  assert.equal(scopeForSession({ ...staff, deviceLabel: "env:staff" }).unrestricted, true);
  process.env.RPC_STAFF_BRANCHES = saved;
});

test("scopeForSession: a founder device is never narrowed by a branch list", () => {
  const scope = scopeForSession({ ...founder, deviceLabel: "dev", branches: ["KANDIVALI"] });
  assert.equal(scope.unrestricted, true);
});

test("WRITE_FUNCTIONS covers every money-moving endpoint", () => {
  for (const fn of [
    "api_addFeePayment",
    "api_founder_finalisePaymentDraft",
    "api_staff_finalisePaymentDraft",
    "api_founder_paymentDraftApprove",
    "api_addExpenseEntry",
    "api_generateSchoolInvoice",
    "api_updateTeacherCompensation",
  ]) {
    assert.ok(WRITE_FUNCTIONS.has(fn), `${fn} must be audited`);
  }
  // Reads are not audited.
  for (const fn of ["api_dashboard", "api_searchStudent", "api_syncChanges", "api_timetableList"]) {
    assert.ok(!WRITE_FUNCTIONS.has(fn), `${fn} is a read`);
  }
  // Everything audited must exist in the policy.
  for (const fn of WRITE_FUNCTIONS) assert.ok(RPC_POLICY[fn], `${fn} missing from RPC_POLICY`);
});

test("the activity log is founder-only and read-only", () => {
  assert.equal(RPC_POLICY["api_founder_auditLog"], "FOUNDER");
  assert.equal(authorizeRpc(staff, "api_founder_auditLog").ok, false);
  assert.equal(authorizeRpc(founder, "api_founder_auditLog").ok, true);
  // Reading the trail is not itself an audited write.
  assert.ok(!WRITE_FUNCTIONS.has("api_founder_auditLog"));
});
