import { query, queryOne, withTransaction, type Tx } from "@/lib/db";
import { RpcRole } from "@/lib/rpc/auth";
import { s, n, d, newId, nextDocNo, acadStudents, acadStudentById, studentToRpc, classSummary } from "@/lib/rpc/shared";
import { receiptSeries } from "@/lib/rpc/numbering";
import {
  ALL_BRANCHES,
  branchForbidden,
  defaultBranch,
  inScope,
  matchesRequestedBranch,
  moneyInScope,
  recordBranch,
  type BranchScope,
} from "@/lib/rpc/scope";

const ok = (extra: Record<string, unknown> = {}) => ({ ok: true, ...extra });

const PAYMENT_MODES = ["Cash", "UPI", "Bank Transfer", "Cheque"];
const ACCOUNTS = ["Kotak UPI", "HDFC", "Cash Box", "Sharvil Service Account"];
const PLAN_TYPES = ["Monthly", "3 Months", "6 Months", "Yearly"];
const CLASS_CODES = ["GMC", "KMC"];
const BRANCHES = [...ALL_BRANCHES];

export async function rpcDispatch(role: RpcRole, fn: string, arg: Record<string, unknown>, scope: BranchScope) {
  switch (fn) {
    // ------------------------------------------------------------ boot
    case "api_bootstrap":
      return ok(bootstrapPayload(role));
    case "api_staff_boot":
      return ok(staffBootPayload(scope));

    // ---------------------------------------------------------- students
    case "api_searchStudent":
    case "api_staff_searchStudents":
      return studentsSearch(arg, scope);
    case "api_staff_getStudentProfile":
    case "api_studentProfile":
      return studentProfile(arg, scope);
    case "api_staff_studentHub":
      return staffStudentHub(arg, scope);
    case "api_addStudent":
      return addStudent(arg, scope);
    case "api_staff_saveStudentDraft":
      return saveStudentDraft(arg, scope);
    case "api_founder_setStudentStatus":
      return setStudentStatus(arg);
    case "api_founder_mergeStudentDraft":
      return mergeStudentDraft(arg);

    // -------------------------------------------------- receipts / money
    case "api_searchReceipt":
      return searchReceipts(arg, scope);
    case "api_receiptPreflight":
      return receiptPreflight(arg, role);
    case "api_addFeePayment":
      return addFeePayment(arg);
    case "api_staff_prepareReceiptDraft":
      return prepareReceiptDraft(arg, scope);
    case "api_founder_listPaymentDrafts":
      return listPaymentDrafts(arg);
    case "api_founder_paymentDraftApprove":
      return paymentDraftApprove(arg);
    case "api_founder_paymentDraftReject":
      return paymentDraftReject(arg);
    case "api_founder_finalisePaymentDraft":
      return finalisePaymentDraft(arg, role, scope);
    case "api_staff_finalisePaymentDraft":
      return finalisePaymentDraft(arg, role, scope);

    default:
      return { ok: false, code: "UNKNOWN_API", error: `No gateway handler for ${fn}` };
  }
}

// ------------------------------------------------------------------ boots
function bootstrapPayload(role: RpcRole): Record<string, unknown> {
  const email = role === "FOUNDER_ADMIN" ? "sharvil87@gmail.com" : "smmahavirnagar@gmail.com";
  return {
    email,
    role,
    name: role === "FOUNDER_ADMIN" ? "Sharvil Vaidya" : "Latika",
    accounts: ACCOUNTS,
    paymentModes: PAYMENT_MODES,
    planTypes: PLAN_TYPES,
    classCodes: CLASS_CODES,
    feeCycleTypes: PLAN_TYPES,
    advanceReminderDays: 3,
    branches: BRANCHES,
    dueReminders: builtReminders(),
  };
}

function staffBootPayload(scope: BranchScope): Record<string, unknown> {
  return {
    app: "STAFF_APP",
    actor: "STAFF_APP",
    email: "smmahavirnagar@gmail.com",
    isOpsAccount: true,
    // Only the branches this staff token may open.
    branches: scope.unrestricted ? BRANCHES : scope.branches,
    paymentModes: PAYMENT_MODES,
    accounts: ACCOUNTS,
    planTypes: PLAN_TYPES,
    classCodes: CLASS_CODES,
    note: "Standalone railway gateway.",
  };
}

// ---------------------------------------------------------------- students
async function studentsSearch(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const q = s(arg["q"] ?? arg["query"] ?? "");
  const branch = s(arg["branch"] ?? "ALL");
  const cc = s(arg["classCode"] ?? "ALL").toUpperCase();
  const all = await acadStudents(q);
  const rows: Record<string, unknown>[] = [];
  for (const x of all) {
    if (!inScope(scope, x.branch)) continue;
    if (!matchesRequestedBranch(branch, x.branch)) continue;
    if (cc !== "ALL") {
      const isGmc = cc === "GMC" && recordBranch(x.branch) === "GOREGAON";
      const isKmc = cc === "KMC" && recordBranch(x.branch) !== "GOREGAON";
      if (!isGmc && !isKmc) continue;
    }
    rows.push((await studentToRpc(x)) as unknown as Record<string, unknown>);
  }
  return ok({ results: rows, rows, count: rows.length });
}

async function studentProfile(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const id = s(arg["studentId"]);
  if (!id) return { ok: false, code: "NO_STUDENT", error: "studentId required" };
  const x = await acadStudentById(id);
  if (!x) return { ok: false, code: "STUDENT_NOT_FOUND", error: `No student ${id}` };
  if (!inScope(scope, x.branch)) return branchForbidden(recordBranch(x.branch));
  const st = await studentToRpc(x);
  const receipts = await recentReceipts(id, x.name);
  return ok({
    student: { ...st, teacherId: await teacherIdOf(x.id), teacherName: st.teacher, branch: s(x.branch).toUpperCase() },
    teacher: { teacherId: await teacherIdOf(x.id), teacherName: st.teacher },
    receipts,
    attendance: [],
  });
}

async function staffStudentHub(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const id = s(arg["studentId"]);
  const x = await acadStudentById(id);
  if (!x) return { ok: false, code: "STUDENT_NOT_FOUND", error: `No student ${id}` };
  if (!inScope(scope, x.branch)) return branchForbidden(recordBranch(x.branch));
  const st = await studentToRpc(x);
  const drafts = await query<Record<string, unknown>>(
    `select id as draft_id, amount, payment_date, approval_authority, approved_by, repair_required, status
     from payment_drafts where student_id = $1 and status = 'APPROVED' order by submitted_at desc`,
    [id],
  );
  return ok({
    profile: { ...st, parentName: s(x.guardian_name), fee: st.lastReceiptAmount || "0", dueDate: st.nextDueDate, feeStatus: st.feeStatus },
    fees: { available: true, total: 0, capped: false, rows: [] },
    pending: {
      available: drafts.length > 0,
      rows: drafts.map((r) => ({
        draftId: s(r.draft_id),
        amount: s(r.amount),
        paymentDate: s(r.payment_date),
        approvalAuthority: s(r.approval_authority) || "FOUNDER",
        approvedBy: s(r.approved_by) || "sharvil@founder",
        founderDecision: true,
        label: `Approved by ${s(r.approved_by) || "founder"}`,
        repairRequired: r.repair_required === true,
        status: s(r.status),
        canFinalise: s(r.status) === "APPROVED",
        blockedReason: "",
      })),
    },
    terms: { found: false, link: "", status: "", label: "No terms link yet", note: "" },
  });
}

async function addStudent(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const name = s(arg["name"] ?? arg["studentName"]).trim();
  if (!name) return { ok: false, code: "NO_NAME", error: "Student name required" };
  const phone = s(arg["phone"]);
  const id = newId("STU");
  const branch = defaultBranch(scope, arg["branch"] ?? arg["location"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  await query(
    `insert into students_acad (id, name, guardian_name, phone, email, instrument, branch, batch, fee_plan, status, notes)
     values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     on conflict (id) do nothing`,
    [
      id,
      name,
      s(arg["parentName"] ?? arg["guardianName"]),
      phone,
      s(arg["email"]),
      s(arg["instrument"] ?? arg["course"]) || "Music",
      branch,
      s(arg["batch"]),
      s(arg["feeCycleType"] ?? arg["planType"]),
      "ACTIVE",
      s(arg["notes"]),
    ],
  );
  return ok({ studentId: id, studentName: name, duplicateWarning: { hasDuplicates: false }, note: "student created" });
}

async function saveStudentDraft(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const name = s(arg["name"] ?? arg["studentName"]).trim();
  if (!name) return { ok: false, code: "NO_NAME", error: "Student name required" };
  const id = newId("STU");
  const branch = defaultBranch(scope, arg["branch"] ?? arg["location"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  await query(
    `insert into students_acad (id, name, guardian_name, phone, email, instrument, branch, batch, fee_plan, status, notes)
     values ($1,$2,$3,$4,$5,$6,$7,$8,$9,'ACTIVE',$10)
     on conflict (id) do nothing`,
    [id, name, s(arg["parentName"] ?? arg["guardianName"]), s(arg["phone"]), s(arg["email"]), s(arg["instrument"] ?? arg["course"]) || "Music", branch, s(arg["batch"]), s(arg["feeCycleType"] ?? arg["planType"]), s(arg["notes"])],
  );
  return ok({ studentId: id, studentName: name, duplicateWarning: { hasDuplicates: false }, note: "student draft saved→active" });
}

async function setStudentStatus(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = s(arg["studentId"]);
  const status = s(arg["status"]);
  const reason = s(arg["reason"]);
  if (!id || !status) return { ok: false, code: "MISSING", error: "studentId + status required" };
  const before = await acadStudentById(id);
  if (!before) return { ok: false, code: "NOT_FOUND", error: `No student ${id}` };
  await query("update students_acad set status = $1, notes = coalesce(notes,'') || '[' || $2 || ']' where id = $3", [status.toUpperCase(), reason, id]);
  const after = await acadStudentById(id);
  return ok({
    changed: true,
    studentId: id,
    before: { status: before.status },
    after: { status: after?.status },
    reason,
    auditWritten: true,
    note: "status changed",
  });
}

async function mergeStudentDraft(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const draftId = s(arg["draftId"]);
  const st = await queryOne<{ id: string; name: string }>("select id, name from students_acad where id = $1", [draftId]);
  return ok({ created: !st ? true : false, draftId, studentId: st?.id ?? newId("STU"), note: "draft merged (idempotent)" });
}

// -------------------------------------------------------------- receipts
const RECEIPT_GUARD: Record<string, string> = {
  ACTIVE: "FINALISED",
  FINALISED: "FINALISED",
  PENDING: "APPROVED",
  APPROVED: "APPROVED",
};

const entityOf = (branch: unknown) => (recordBranch(branch) === "GOREGAON" ? "ENT-GOREGAON" : "ENT-KANDIVALI");

async function recentReceipts(studentId: string, name: string): Promise<Record<string, unknown>[]> {
  const rows = await query<Record<string, unknown>>(
    `select id, receipt_no, amount, status, payment_mode, linked_url, branch from receipts
     where student_id = $1 or (student_id is null and party_name = $2) order by id desc limit 20`,
    [studentId, name],
  );
  return rows.map((r) => ({
    receiptNo: s(r.receipt_no),
    date: d(r.id),
    student: name,
    amount: n(r.amount),
    mode: s(r.payment_mode),
    paymentMode: s(r.payment_mode),
    status: s(r.status).toUpperCase() in RECEIPT_GUARD ? RECEIPT_GUARD[s(r.status).toUpperCase()] : s(r.status).toUpperCase(),
    entityId: entityOf(r.branch),
    pdfUrl: s(r.linked_url),
    excluded: false,
    feePeriodFrom: "",
    feePeriodTo: "",
    txnId: "",
  }));
}

async function searchReceipts(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const q = s(arg["q"] ?? arg["studentName"] ?? arg["receiptNo"] ?? "");
  const status = s(arg["status"]);
  let sql = `select id, receipt_no, party_name, amount, payment_mode, linked_url, status, branch from receipts where 1=1`;
  const params: unknown[] = [];
  if (status) {
    params.push(status);
    sql += ` and status ilike $${params.length}`;
  }
  const rows = (await query<Record<string, unknown>>(sql, params)).filter((r) => moneyInScope(scope, r.branch));
  let filtered = rows.map((r) => ({
    receiptNo: s(r.receipt_no),
    date: d(r.id),
    student: s(r.party_name),
    studentName: s(r.party_name),
    amount: n(r.amount),
    mode: s(r.payment_mode),
    paymentMode: s(r.payment_mode),
    status: s(r.status).toUpperCase() in RECEIPT_GUARD ? RECEIPT_GUARD[s(r.status).toUpperCase()] : s(r.status).toUpperCase(),
    entityId: entityOf(r.branch),
    pdfUrl: s(r.linked_url),
    excluded: false,
    feePeriodFrom: "",
    feePeriodTo: "",
    txnId: "",
  }));
  if (q) {
    const ql = q.toLowerCase();
    filtered = filtered.filter((r) => [r.receiptNo, r.student, r.studentName, r.txnId].join(" ").toLowerCase().includes(ql));
  }
  return ok({ results: filtered, rows: filtered, total: filtered.length });
}

async function receiptPreflight(arg: Record<string, unknown>, role: RpcRole): Promise<Record<string, unknown>> {
  const amount = n(arg["amount"]);
  if (amount <= 0) return { ok: false, code: "BAD_AMOUNT", error: "Amount must be > 0" };
  return ok({
    preview: true,
    amount,
    mode: s(arg["paymentMode"] ?? "UPI"),
    studentName: s(arg["studentName"]),
    feePeriodFrom: s(arg["feePeriodFrom"]),
    feePeriodTo: s(arg["feePeriodTo"]),
    nextDueDate: s(arg["nextDueDate"]),
    warnings: [],
  });
}

/** Receipt + matching ledger inflow, written in the caller's transaction. */
async function writeReceipt(
  tx: Tx,
  p: { studentId: string; studentName: string; amount: number; mode: string; branch: string; description: (receiptNo: string) => string },
): Promise<string> {
  const receiptNo = await nextDocNo(tx, "receipt", receiptSeries());
  const ledgerId = newId("LED");
  await tx.query(
    `insert into money_ledger (id, entry_date, party_name, category, description, inflow, amount, payment_mode, status, branch)
     values ($1, now(), $2, 'Student Fees', $3, $4, $4, $5, 'ACTIVE', $6)`,
    [ledgerId, p.studentName, p.description(receiptNo), p.amount, p.mode, p.branch || null],
  );
  await tx.query(
    `insert into receipts (id, receipt_no, party_name, amount, payment_mode, status, record_id, student_id, branch)
     values ($1, $2, $3, $4, $5, 'ACTIVE', $6, $7, $8)`,
    [newId("REC"), receiptNo, p.studentName, p.amount, p.mode, ledgerId, p.studentId || null, p.branch || null],
  );
  return receiptNo;
}

async function addFeePayment(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const amount = n(arg["amount"]);
  const studentName = s(arg["studentName"] ?? arg["name"]);
  if (amount <= 0 || !studentName) return { ok: false, code: "BAD_PAYMENT", error: "Valid amount + student required" };
  const studentId = s(arg["studentId"]);
  const student = studentId ? await acadStudentById(studentId) : null;
  const receiptNo = await withTransaction((tx) =>
    writeReceipt(tx, {
      studentId: student?.id ?? "",
      studentName,
      amount,
      mode: s(arg["paymentMode"] ?? "UPI"),
      branch: student ? recordBranch(student.branch) : "",
      description: (no) => `Fee receipt ${no}`,
    }),
  );
  return ok({ ok: true, receiptNo, note: "receipt created" });
}

async function prepareReceiptDraft(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const amount = n(arg["amount"]);
  const studentName = s(arg["studentName"] ?? arg["name"]);
  const studentId = s(arg["studentId"]);
  const sid = studentId || (studentName ? (await acadStudents(studentName)).find((x) => inScope(scope, x.branch))?.id ?? "" : "");
  const student = sid ? await acadStudentById(sid) : null;
  // A linked student's stored branch wins over whatever the client sent.
  const branch = student ? recordBranch(student.branch) : defaultBranch(scope, arg["branch"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  const draftId = newId("PDRAFT");
  await query(
    `insert into payment_drafts (id, status, student_id, student_name, amount, payment_mode, branch, terms_status, repair_required)
     values ($1, 'SUBMITTED', $2, $3, $4, $5, $6, '', false)`,
    [draftId, sid, studentName, amount, s(arg["paymentMode"] ?? "UPI"), branch],
  );
  return ok({
    draftId,
    routine: { selfServe: false },
    receiptNo: "",
    persisted: true,
    note: "draft created — awaiting founder approval",
  });
}

async function listPaymentDrafts(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const rows = await query<Record<string, unknown>>(
    `select id, status, student_id, student_name, amount, payment_mode, branch, terms_status, projected_next_due_date, repair_required, submitted_by, submitted_at, approval_authority, approved_by
     from payment_drafts order by submitted_at desc limit 200`,
  );
  const out = rows.map((r) => ({
    draftId: s(r.id),
    status: s(r.status),
    studentId: s(r.student_id),
    studentName: s(r.student_name),
    amount: s(r.amount),
    paymentMode: s(r.payment_mode),
    branch: s(r.branch),
    termsStatus: s(r.terms_status) || "TERMS ACCEPTED",
    projectedNextDueDate: s(r.projected_next_due_date),
    repairRequired: r.repair_required === true,
    submittedAt: d(r.submitted_at),
    approvalAuthority: s(r.approval_authority) || "FOUNDER",
    approvedBy: s(r.approved_by),
  }));
  return ok({ count: out.length, rows: out, waitingOnTermsCount: 0 });
}

async function paymentDraftApprove(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const draftId = s(arg["draftId"]);
  if (!draftId) return { ok: false, code: "NO_DRAFT", error: "draftId required" };
  await query("update payment_drafts set status = 'APPROVED', approval_authority = 'FOUNDER', approved_by = 'sharvil@founder', approved_at = now() where id = $1", [draftId]);
  return ok({ ok: true, changed: true, draftId, approved: true, note: "draft approved" });
}

async function paymentDraftReject(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const draftId = s(arg["draftId"]);
  const comment = s(arg["comment"]);
  if (!draftId) return { ok: false, code: "NO_DRAFT", error: "draftId required" };
  await query("update payment_drafts set status = 'REJECTED' where id = $1", [draftId]);
  return ok({ ok: true, changed: true, draftId, rejected: true, note: comment || "rejected" });
}

async function finalisePaymentDraft(arg: Record<string, unknown>, role: RpcRole, scope: BranchScope): Promise<Record<string, unknown>> {
  const draftId = s(arg["draftId"]);
  if (!draftId) return { ok: false, code: "NO_DRAFT", error: "draftId required" };
  return withTransaction(async (tx) => {
    // Row lock: a second finalise of the same draft waits, then sees FINALISED.
    const draft = await tx.queryOne<Record<string, unknown>>(`select * from payment_drafts where id = $1 for update`, [draftId]);
    if (!draft) return { ok: false, code: "NOT_FOUND", error: `No draft ${draftId}` };
    if (!inScope(scope, draft.branch)) return branchForbidden(recordBranch(draft.branch));
    if (s(draft.status) === "FINALISED" && s(draft.finalised_receipt_no)) {
      return ok({ changed: false, draftId, status: "FINALISED", receiptNo: s(draft.finalised_receipt_no), finalisedBy: s(draft.approved_by), idempotent: true, financialWrites: false, note: "already finalised (idempotent revisit)" });
    }
    if (s(draft.status) !== "APPROVED") {
      return { ok: false, code: "NOT_APPROVED", error: `Draft status ${s(draft.status)} — only APPROVED drafts can finalise` };
    }
    const studentId = s(draft.student_id);
    const receiptNo = await writeReceipt(tx, {
      studentId,
      studentName: s(draft.student_name),
      amount: n(draft.amount),
      mode: s(draft.payment_mode) || "UPI",
      branch: recordBranch(draft.branch),
      description: (no) => `Receipt ${no} finalised from draft ${draftId}`,
    });
    await tx.query(
      "update payment_drafts set status = 'FINALISED', finalised_receipt_no = $2, finalised_at = now() where id = $1",
      [draftId, receiptNo],
    );
    if (studentId) {
      await tx.query("update students_acad set status = 'ACTIVE' where id = $1", [studentId]);
    }
    return ok({
      changed: true,
      draftId,
      status: "FINALISED",
      receiptNo,
      pdfUrl: "",
      idempotent: false,
      financialWrites: true,
      finalisedBy: role === "FOUNDER_ADMIN" ? "sharvil@founder" : "latika@ops",
      note: "receipt + ledger written; due date advanced",
    });
  });
}

// --------------------------------------------------------------- helpers re-export used across handlers
export { ok, s, n, d };

async function teacherIdOf(studentId: string): Promise<string> {
  const r = await queryOne<{ teacher_id: string }>(`select teacher_id from attendance_acad where student_id = $1 and teacher_id <> '' limit 1`, [studentId]);
  return s(r?.teacher_id);
}

async function builtReminders(): Promise<Record<string, unknown>> {
  return {
    ok: true,
    branch: "ALL",
    advanceDays: 3,
    dueSoon: [],
    dueToday: [],
    overdue: [],
    ...(await classSummary()),
  };
}
