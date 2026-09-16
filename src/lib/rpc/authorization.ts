import type { RpcRole, RpcSession } from "@/lib/rpc/auth";
import { makeScope, type BranchScope } from "./scope.ts";

// ============================================================
// CENTRALIZED RPC AUTHORIZATION (fail-closed)
//
// Every RPC function exposed through POST /api/rpc must have EXACTLY ONE
// entry in ALLOWED_BY. If a function is missing from the map, or a role is
// below the required one, the request is rejected BEFORE the handler runs.
//
// Role hierarchy:  FOUNDER_ADMIN >= OPS_USER.
//   - FOUNDER_ADMIN may call anything.
//   - OPS_USER may call only entries marked OPS_USER.
//
// This is the PRIMARY authorization boundary. Handlers never re-audit role
// beyond what the policy already guarantees. Unknown functions fail closed.
// ============================================================

export type RequiredRole = "FOUNDER" | "STAFF";

const ROLE_RANK: Record<RpcRole, number> = { FOUNDER_ADMIN: 2, OPS_USER: 1 };

export const STAFF = "STAFF" as const;
export const FOUNDER = "FOUNDER" as const;

/**
 * Every RPC function the gateway may execute, with the minimum role required.
 * Derived from:
 *  - function name (api_founder_* = founder-only, api_staff_* = staff)
 *  - Flutter shared screens that branch on the staff flag
 *  - money/financial business rules (founder === money authority)
 *  - existing ApiService + demo_api + shell nav usage
 */
export const RPC_POLICY: Record<string, RequiredRole> = {
  // ------------------------------------------------------------ boot
  api_bootstrap: FOUNDER,
  api_staff_boot: STAFF,

  // ---------------------------------------------------------- students
  // api_searchStudent / api_studentProfile: founder surface; staff has
  // dedicated api_staff_* equivalents.
  api_searchStudent: FOUNDER,
  api_studentProfile: FOUNDER,
  api_staff_searchStudents: STAFF,
  api_staff_getStudentProfile: STAFF,
  api_staff_studentHub: STAFF,
  api_staff_saveStudentDraft: STAFF,
  // api_addStudent is founder-only (staff drafts, founder merges).
  api_addStudent: FOUNDER,
  api_founder_setStudentStatus: FOUNDER,
  api_founder_mergeStudentDraft: FOUNDER,

  // -------------------------------------------------- receipts / money
  // Money creation/approval/finalisation = founder.
  api_addFeePayment: FOUNDER,
  api_receiptPreflight: FOUNDER,
  api_founder_listPaymentDrafts: FOUNDER,
  api_founder_paymentDraftApprove: FOUNDER,
  api_founder_paymentDraftReject: FOUNDER,
  api_founder_finalisePaymentDraft: FOUNDER,
  // Staff can SEARCH receipts (shared receipts screen), propose drafts, and
  // execute a founder-APPROVED draft's finalisation where the backend allows.
  api_searchReceipt: STAFF,
  api_staff_prepareReceiptDraft: STAFF,
  api_staff_finalisePaymentDraft: STAFF,

  // ---------------------------------------------------------- dashboard
  // Shared dashboard shell (both roles see operational + collection figures).
  api_dashboard: STAFF,
  api_dueReminders: STAFF,

  // ------------------------------------------------------------ teachers
  // Teacher list/profile are read surfaces reachable from both shells.
  api_listTeachers: STAFF,
  api_teacherProfile: STAFF,
  // Teacher WRITES + payouts = founder only.
  api_addTeacher: FOUNDER,
  api_updateTeacherStatus: FOUNDER,
  api_updateTeacherCompensation: FOUNDER,
  api_teacherPayoutPreview: FOUNDER,
  // Paying a teacher is money leaving the academy: founder only.
  api_recordTeacherPayout: FOUNDER,
  api_teacherPayoutHistory: FOUNDER,

  // ------------------------------------------------- cashbook / expenses
  // Staff submits an expense DRAFT; founder records real expense + ledger read.
  api_cashbookReport: STAFF,
  api_staff_submitExpenseDraft: STAFF,
  api_addExpenseEntry: FOUNDER,

  // ------------------------------------------------------- school invoices
  // Shared across roles: staff can also generate/read school invoices.
  api_generateSchoolInvoice: STAFF, // invoice = money document
  api_listSchoolInvoices: STAFF,
  api_getSchoolInvoice: STAFF,

  // ------------------------------------------------------------ timetable
  // Shared across roles: staff reads + edits (add/edit enables both shells).
  api_timetableList: STAFF,
  api_timetableCreate: STAFF,
  api_timetableUpdate: STAFF,
  api_timetableDelete: STAFF,

  // ------------------------------------------------------ attendance/today
  api_staff_attendanceRoster: STAFF,
  api_staff_markAttendance: STAFF,
  api_staff_todaysTasks: STAFF,
  api_staff_doToday: STAFF,
  api_staff_todaysClasses: STAFF,
  api_staff_resolveTodaysClass: STAFF,
  api_staff_scheduleSession: STAFF,
  api_staff_sessionRoster: STAFF,
  api_staff_feeDueList: STAFF,

  // ------------------------------------------------------------- inquiries
  api_staff_inquiryQueue: STAFF,
  api_staff_inquiryQuickAdd: STAFF,
  api_staff_inquiryTransition: STAFF,

  // -------------------------------------------------------------- approvals
  api_founder_approvalsList: FOUNDER, // founder approval centre
  api_staff_listMyApprovals: STAFF, // staff sees own requests only

  // -------------------------------------------------------------- comm
  api_staff_commGenerate: STAFF,

  // -------------------------------------------------------------- sync
  // Revision sync is used by both shells on their own entity sets.
  api_syncChanges: STAFF,
};

export interface AuthzResult {
  ok: boolean;
  code: "ROLE_FORBIDDEN" | "UNKNOWN_API" | "BRANCH_FORBIDDEN";
  required?: RequiredRole;
  message?: string;
}

/** True when the session role satisfies the policy's required role. */
export function satisfiesRole(sessionRole: RpcRole, required: RequiredRole): boolean {
  const requiredRank = required === "FOUNDER" ? 2 : 1;
  return ROLE_RANK[sessionRole] >= requiredRank;
}

/**
 * Fail-closed authorization gate. Returns ok only when:
 *  - the function exists in RPC_POLICY, AND
 *  - the authenticated role meets the required role.
 * Unknown functions return UNKNOWN_API (never executed).
 */
export function authorizeRpc(session: RpcSession, functionName: string): AuthzResult {
  const required = RPC_POLICY[functionName];
  if (!required) {
    return { ok: false, code: "UNKNOWN_API", message: `No policy for ${functionName}` };
  }
  if (!satisfiesRole(session.role, required)) {
    return {
      ok: false,
      code: "ROLE_FORBIDDEN",
      required,
      message: `${session.role} is not allowed to call ${functionName} (requires ${required})`,
    };
  }
  return { ok: true, code: "ROLE_FORBIDDEN" as const };
}

// ============================================================
// BRANCH / ENTITY ISOLATION
//
// Separate axis from role. Staff must stay in their branch; founder may be
// broader. The session's branch allow-list comes from the token mapping
// (auth.ts). Client-supplied branch/entity/scope values are NEVER trusted
// for isolation — they are checked against the session's allowed branches.
// ============================================================

/**
 * Staff branches come only from RPC_STAFF_BRANCHES (e.g. "KANDIVALI" or
 * "GOREGAON,KANDIVALI"). Unset means NO branches — fail closed.
 */
export function roleAllowedBranches(role: RpcRole): string[] {
  if (role === "FOUNDER_ADMIN") return ["GOREGAON", "KANDIVALI"];
  const env = process.env.RPC_STAFF_BRANCHES || "";
  return env.split(",").map((s) => s.trim().toUpperCase()).filter(Boolean);
}

/** Record-level scope handed to handlers (see scope.ts). */
export function scopeForSession(session: RpcSession): BranchScope {
  // A device token may carry its own allow-list; otherwise fall back to the
  // role default (founder: all, staff: RPC_STAFF_BRANCHES).
  if (session.role !== "FOUNDER_ADMIN" && session.branches?.length) {
    return makeScope(session.branches);
  }
  return makeScope(roleAllowedBranches(session.role));
}

/**
 * Functions that change data. Used for the audit trail, and to decide what is
 * worth recording; reads are not logged.
 */
export const WRITE_FUNCTIONS = new Set<string>([
  "api_addStudent", "api_staff_saveStudentDraft", "api_founder_setStudentStatus", "api_founder_mergeStudentDraft",
  "api_addFeePayment", "api_staff_prepareReceiptDraft",
  "api_founder_paymentDraftApprove", "api_founder_paymentDraftReject",
  "api_founder_finalisePaymentDraft", "api_staff_finalisePaymentDraft",
  "api_addTeacher", "api_updateTeacherStatus", "api_updateTeacherCompensation", "api_recordTeacherPayout",
  "api_addExpenseEntry", "api_staff_submitExpenseDraft",
  "api_generateSchoolInvoice",
  "api_timetableCreate", "api_timetableUpdate", "api_timetableDelete",
  "api_staff_markAttendance", "api_staff_resolveTodaysClass", "api_staff_scheduleSession",
  "api_staff_inquiryQuickAdd", "api_staff_inquiryTransition",
]);

/**
 * Resolve the branch implied by an RPC argument (branch/scope/entityId).
 * Returns '' when the argument carries no enforceable branch (e.g. 'ALL').
 */
export function impliedBranch(arg: Record<string, unknown>): string {
  const v = (k: string) => {
    const x = arg[k];
    return x == null ? "" : String(x).toUpperCase();
  };
  const branch = v("branch");
  if (branch && branch !== "ALL") return branch;
  const scope = v("scope");
  if (scope && scope !== "ALL" && scope !== "CONSOLIDATED") return scope;
  const entity = v("entityId") || v("entity_id");
  if (entity) {
    if (entity.startsWith("ENT-GOREGAON")) return "GOREGAON";
    if (entity.startsWith("ENT-KANDIVALI")) return "KANDIVALI";
  }
  const classCode = v("classCode");
  if (classCode === "GMC") return "GOREGAON";
  if (classCode === "KMC") return "KANDIVALI";
  const location = v("location");
  if (location && location !== "ALL") return location;
  return "";
}

/**
 * Enforce branch isolation for a staff session. Founder is allowed all
 * branches by policy. Returns ok only when an implied branch is inside the
 * session's allowed set (or no branch is implied).
 */
export function authorizeBranch(session: RpcSession, arg: Record<string, unknown>): AuthzResult {
  if (session.role === "FOUNDER_ADMIN") return { ok: true, code: "BRANCH_FORBIDDEN" as const };
  const allowed = roleAllowedBranches(session.role);
  const implied = impliedBranch(arg);
  if (!implied) return { ok: true, code: "BRANCH_FORBIDDEN" as const };
  if (allowed.includes(implied)) return { ok: true, code: "BRANCH_FORBIDDEN" as const };
  return {
    ok: false,
    code: "BRANCH_FORBIDDEN",
    message: `OPS_USER is not authorised for branch ${implied} (allowed: ${allowed.join(", ")})`,
  };
}