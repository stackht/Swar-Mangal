// ============================================================
// BRANCH SCOPE (record-level isolation)
//
// authorization.ts rejects a request whose *arguments* name a forbidden
// branch. That alone is not enough: a staff call can reach a record by id
// (studentId, draftId, timetable id) without naming a branch. Handlers
// therefore check the branch STORED on each record against this scope.
//
// Pure module (no runtime imports) so backend-tests can load it directly.
// ============================================================

export const ALL_BRANCHES = ["GOREGAON", "KANDIVALI"] as const;

export interface BranchScope {
  /** True when every branch is allowed (founder, or staff allowed all). */
  unrestricted: boolean;
  branches: string[];
}

export function makeScope(branches: string[]): BranchScope {
  const unique = Array.from(new Set(branches.map((b) => b.trim().toUpperCase()).filter(Boolean)));
  return { unrestricted: ALL_BRANCHES.every((b) => unique.includes(b)), branches: unique };
}

/**
 * Branch of a student-like record (students, drafts, timetable, inquiries,
 * school invoices). Existing convention: blank branch means KANDIVALI.
 */
export function recordBranch(raw: unknown): string {
  const v = raw == null ? "" : String(raw).trim().toUpperCase();
  if (v.includes("GOR")) return "GOREGAON";
  if (v === "" || v.includes("KAN")) return "KANDIVALI";
  return v;
}

/** Is a student-like record (blank = KANDIVALI) inside the scope? */
export function inScope(scope: BranchScope, rawBranch: unknown): boolean {
  return scope.unrestricted || scope.branches.includes(recordBranch(rawBranch));
}

/**
 * Is a money record (receipts, ledger) inside the scope? Blank means
 * "not linked to a branch", which only an unrestricted scope may see.
 */
export function moneyInScope(scope: BranchScope, rawBranch: unknown): boolean {
  if (scope.unrestricted) return true;
  const v = rawBranch == null ? "" : String(rawBranch).trim();
  return v !== "" && scope.branches.includes(recordBranch(v));
}

/**
 * Branch filter requested by the client ("ALL" / blank = no filter),
 * applied on top of the scope.
 */
export function matchesRequestedBranch(requested: unknown, rawBranch: unknown): boolean {
  const r = requested == null ? "" : String(requested).trim().toUpperCase();
  if (r === "" || r === "ALL" || r === "CONSOLIDATED") return true;
  return recordBranch(rawBranch) === recordBranch(r);
}

/** Branch to use for a new record when the client did not send one. */
export function defaultBranch(scope: BranchScope, requested: unknown): string {
  const r = requested == null ? "" : String(requested).trim().toUpperCase();
  if (r && r !== "ALL") return recordBranch(r);
  return !scope.unrestricted && scope.branches.length ? scope.branches[0] : "KANDIVALI";
}

export const branchForbidden = (branch: string) => ({
  ok: false,
  code: "BRANCH_FORBIDDEN",
  error: `Not authorised for branch ${branch || "(none)"}`,
});
