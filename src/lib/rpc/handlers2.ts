import { query, queryOne, withTransaction } from "@/lib/db";
import { RpcRole } from "@/lib/rpc/auth";
import { s, n, d, newId, nextDocNo, bumpRevisions, currentRevisions, acadStudents, acadStudentById, acadTeachers, acadTeacherById, studentToRpc, studentsToRpc, teacherToRpc, classSummary } from "@/lib/rpc/shared";
import { schoolInvoiceSeries } from "@/lib/rpc/numbering";
import { feeState, todayIso, DEFAULT_ADVANCE_DAYS, type FeeState } from "@/lib/rpc/fees";
import { money, payoutStatus, payoutBalance, isServiceMonth } from "@/lib/rpc/payouts";
import {
  branchForbidden,
  defaultBranch,
  inScope,
  matchesRequestedBranch,
  moneyInScope,
  recordBranch,
  type BranchScope,
} from "@/lib/rpc/scope";

const ok = (extra: Record<string, unknown> = {}) => ({ ok: true, ...extra });

export async function dispatch2(role: RpcRole, fn: string, arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  switch (fn) {
    case "api_dashboard":
      return dashboard(arg, scope);
    case "api_dueReminders":
      return dueReminders(scope);
    case "api_cashbookReport":
      return cashbook(arg, scope);
    case "api_addExpenseEntry":
      return addExpense(arg);
    case "api_staff_submitExpenseDraft":
      return submitExpenseDraft(arg, scope);
    case "api_founder_expenseDraftApprove":
      return expenseDraftApprove(arg);
    case "api_founder_expenseDraftReject":
      return expenseDraftReject(arg);
    case "api_listTeachers":
      return listTeachers();
    case "api_addTeacher":
      return addTeacher(arg);
    case "api_teacherProfile":
      return teacherProfile(arg, scope);
    case "api_updateTeacherStatus":
      return updateTeacherStatus(arg);
    case "api_updateTeacherCompensation":
      return updateTeacherCompensation(arg);
    case "api_teacherPayoutPreview":
      return payoutPreview(arg);
    case "api_recordTeacherPayout":
      return recordTeacherPayout(arg, scope);
    case "api_teacherPayoutHistory":
      return payoutHistory(arg);
    case "api_assignSharedStudent":
      return assignSharedStudent(arg);
    case "api_generateSchoolInvoice":
      return generateSchoolInvoice(arg, scope);
    case "api_listSchoolInvoices":
      return listSchoolInvoices(scope);
    case "api_getSchoolInvoice":
      return getSchoolInvoice(arg, scope);
    case "api_timetableList":
      return timetableList(arg, scope);
    case "api_timetableCreate":
      return timetableCreate(arg, scope);
    case "api_timetableUpdate":
      return timetableUpdate(arg, scope);
    case "api_timetableDelete":
      return timetableDelete(arg, scope);
    case "api_staff_attendanceRoster":
      return attendanceRoster(arg, scope);
    case "api_staff_markAttendance":
      return markAttendance(arg, scope);
    case "api_staff_todaysTasks":
    case "api_staff_doToday":
      return todaysTasks(arg, scope);
    case "api_staff_todaysClasses":
      return todaysClasses(arg, scope);
    case "api_staff_resolveTodaysClass":
      return resolveTodaysClass(arg, scope);
    case "api_staff_scheduleSession":
      return scheduleSession(arg, scope);
    case "api_staff_sessionRoster":
      return sessionRoster(arg, scope);
    case "api_staff_feeDueList":
      return feeDueList(scope);
    case "api_staff_inquiryQueue":
      return inquiryQueue(arg, scope);
    case "api_staff_inquiryQuickAdd":
      return inquiryQuickAdd(arg, scope);
    case "api_staff_inquiryTransition":
      return inquiryTransition(arg, scope);
    case "api_founder_approvalsList":
      return founderApprovals();
    case "api_founder_auditLog":
      return auditLog(arg);
    case "api_staff_listMyApprovals":
      return staffMyRequests(scope);
    case "api_staff_commGenerate":
      return commGenerate(arg);
    case "api_syncChanges":
      return syncChanges(arg);
    default:
      return { ok: false, code: "UNKNOWN_API", error: `No gateway handler for ${fn}` };
  }
}

// -------------------------------------------------------------- dashboard
async function dashboard(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const today = new Date().toISOString().slice(0, 10);
  const [ledAll, receiptsAll] = await Promise.all([
    query<{ inflow: string; amount: string; entry_date: string; payment_mode: string; party_name: string; branch: string }>(
      `select inflow, amount, entry_date::text, payment_mode, party_name, branch from money_ledger
       where entry_date >= date_trunc('month', current_date) order by entry_date desc`,
    ),
    query<{ receipt_no: string; amount: string; payment_mode: string; status: string; party_name: string; branch: string; created_at: string }>(
      `select receipt_no, amount, payment_mode, status, party_name, branch, created_at::text from receipts order by id desc limit 100`,
    ),
  ]);
  const led = ledAll.filter((r) => moneyInScope(scope, r.branch));
  const receipts = receiptsAll.filter((r) => moneyInScope(scope, r.branch)).slice(0, 12);

  // Money in only: expenses share this table as outflow rows.
  const inflowOf = (r: { inflow: string }) => (n(r.inflow) > 0 ? n(r.inflow) : 0);
  const monthCollection = led.reduce((a, r) => a + inflowOf(r), 0);
  const todayRows = led.filter((r) => d(r.entry_date) === today);
  const todayCollection = todayRows.reduce((a, r) => a + inflowOf(r), 0);
  const onlineToday = todayRows
    .filter((r) => s(r.payment_mode).toUpperCase() !== "CASH")
    .reduce((a, r) => a + inflowOf(r), 0);
  const cashToday = todayCollection - onlineToday;
  const due = await dueReminders(scope);

  return ok({
    todayCollection,
    monthCollection,
    todayCount: receipts.length,
    monthCount: led.filter((r) => inflowOf(r) > 0).length,
    cashToday,
    onlineToday,
    scope: s(arg["scope"] ?? "ALL"),
    consolidated: s(arg["scope"] ?? "ALL") === "ALL",
    metrics: {
      dueTodayCount: (due["dueToday"] as unknown[]).length,
      dueSoonCount: (due["dueSoon"] as unknown[]).length,
      overdueCount: (due["overdue"] as unknown[]).length,
      feePlanMissingCount: Number(due["notRecorded"] ?? 0),
      termsPendingCount: 0,
    },
    recent: receipts.map((r) => ({
      receiptNo: s(r.receipt_no),
      date: d(r.created_at),
      student: s(r.party_name),
      studentName: s(r.party_name),
      amount: n(r.amount),
      mode: s(r.payment_mode),
      paymentMode: s(r.payment_mode),
      status: s(r.status).toUpperCase(),
      entityId: recordBranch(r.branch) === "GOREGAON" ? "ENT-GOREGAON" : "ENT-KANDIVALI",
      pdfUrl: "",
      excluded: false,
      feePeriodFrom: "",
      feePeriodTo: "",
      txnId: "",
    })),
  });
}

/**
 * Splits students into real due buckets from their stored next_due_date.
 * A student with no recorded due date lands in "notRecorded" — the app says
 * so instead of calling them overdue, which is what this used to do to every
 * active student.
 */
async function dueBuckets(scope: BranchScope) {
  const students = (await acadStudents()).filter((x) => inScope(scope, x.branch));
  const today = todayIso();
  const by: Record<FeeState, typeof students> = {
    OVERDUE: [], DUE_TODAY: [], DUE_SOON: [], PAID: [], UNKNOWN: [], INACTIVE: [],
  };
  for (const x of students) by[feeState(x.next_due_date, today, { status: x.status })].push(x);
  return { students, today, by };
}

async function dueReminders(scope: BranchScope): Promise<Record<string, unknown>> {
  const { by } = await dueBuckets(scope);
  const cls = await classSummary();
  // Only the students actually being chased are expanded (bounded work).
  const rows = async (xs: Awaited<ReturnType<typeof acadStudents>>) =>
    (await studentsToRpc(xs)).map((st) => ({
      studentId: st.studentId,
      studentName: st.studentName,
      phone: st.phone,
      classCode: st.classCode,
      instrument: st.instrument,
      nextDueDate: st.nextDueDate,
      feeStatus: st.feeStatus,
      lastReceiptNo: st.lastReceiptNo,
      amount: st.monthlyFee ?? "",
    }));
  return ok({
    branch: "ALL",
    advanceDays: DEFAULT_ADVANCE_DAYS,
    dueSoon: await rows(by.DUE_SOON),
    dueToday: await rows(by.DUE_TODAY),
    overdue: await rows(by.OVERDUE),
    // Students whose fee plan the academy has not recorded yet.
    notRecorded: by.UNKNOWN.length,
    upToDate: by.PAID.length,
    gmcActive: cls.gmc,
    kmcActive: cls.kmc,
  });
}

// ---------------------------------------------------------------- teachers
async function listTeachers(): Promise<Record<string, unknown>> {
  const rows = await acadTeachers();
  return ok({ teachers: await Promise.all(rows.map(teacherToRpc)) });
}

async function addTeacher(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const name = s(arg["name"] ?? arg["teacherName"]).trim();
  if (!name) return { ok: false, code: "NO_NAME", error: "Teacher name required" };
  const id = newId("TCH");
  await query(
    `insert into teachers_acad (id, name, phone, email, instrument, status) values ($1,$2,$3,$4,$5,'ACTIVE') on conflict (id) do nothing`,
    [id, name, s(arg["phone"]), s(arg["email"]), s(arg["instrument"] ?? arg["primaryRole"]) || "Music"],
  );
  await bumpRevisions(["teachers"]);
  return ok({ teacherId: id, teacherName: name, note: "teacher created" });
}

async function teacherProfile(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const id = s(arg["teacherId"]);
  const t = id ? await acadTeacherById(id) : (await acadTeachers())[0];
  if (!t) return { ok: false, code: "NO_TEACHER", error: `No teacher ${id}` };
  const trpc = await teacherToRpc(t);
  const students = (await acadStudents()).filter((x) => inScope(scope, x.branch));
  const myStudents = (await studentsToRpc(students)).filter((st) => st.teacherId === t.id);
  // Receipts this calendar month from the students this teacher teaches —
  // the old query counted every active receipt ever and called it a month.
  const receipts = await query<{ c: string }>(
    `select count(*)::text as c from receipts r
     where r.status = 'ACTIVE'
       and r.created_at >= date_trunc('month', current_date)
       and r.student_id in (select distinct student_id from attendance_acad
                            where teacher_id = $1 and coalesce(student_id,'') <> '')`,
    [t.id],
  );
  return ok({
    teacher: {
      ...trpc,
      compensationPercent: trpc.academyShare,
      compensationEffectiveFrom: "2026-07-01",
    },
    students: myStudents.slice(0, 50),
    receiptCountThisMonth: Number(receipts[0]?.c ?? 0),
  });
}

async function updateTeacherStatus(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = s(arg["teacherId"]);
  const status = s(arg["newStatus"]);
  const reason = s(arg["reason"]);
  await query("update teachers_acad set status = $1 where id = $2", [status.toUpperCase(), id]);
  await bumpRevisions(["teachers"]);
  return ok({ teacherId: id, oldStatus: "ACTIVE", newStatus: status.toUpperCase(), message: reason || "updated" });
}

async function updateTeacherCompensation(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = s(arg["teacherId"]);
  const pct = n(arg["percentage"]);
  if (!id || pct < 0 || pct > 100) return { ok: false, code: "BAD_PCT", error: "percentage 0..100 required" };
  const existing = await queryOne<{ id: string }>(`select id from payout_rules where teacher_id = $1 order by id limit 1`, [id]);
  if (existing) {
    await query("update payout_rules set percentage = $1 where id = $2", [pct, existing.id]);
  } else {
    await query(
      `insert into payout_rules (id, teacher_id, teacher_name, entity_id, course, payout_type, percentage) values ($1,$2,$3,'ENT-KANDIVALI','', 'PERCENTAGE',$4)`,
      [newId("PRULE"), id, s(arg["teacherName"]), pct],
    );
  }
  await bumpRevisions(["teachers", "payouts"]);
  return ok({ changed: true, teacherId: id, oldPercentage: "", newPercentage: String(pct), effectiveFrom: s(arg["effectiveFrom"]) || "2026-07-01", reason: s(arg["reason"]), auditWritten: true, note: "compensation updated" });
}

/**
 * Teacher payout preview for one month.
 *
 * The previous version joined receipts to attendance on student NAME and
 * counted a receipt once per attendance row, so a student with twenty marked
 * classes inflated their teacher's collection twentyfold (capped at an
 * arbitrary 50 rows), and the requested month was ignored entirely.
 *
 * Now: a receipt counts once, is attributed through the student id it was
 * written with, and only counts inside the requested month. Receipts that
 * cannot be attributed are reported rather than silently dropped.
 */
async function payoutPreview(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const month = isServiceMonth(s(arg["month"])) ? s(arg["month"]) : todayIso().slice(0, 7);
  const monthStart = `${month}-01`;
  const teachers = await acadTeachers();

  const [monthLinks, links, receipts, rules, paidRows, attributions, studentNames] = await Promise.all([
    // Who actually taught this student during the month, and how often.
    query<{ teacher_id: string; student_id: string; classes: string }>(
      `select teacher_id, student_id, count(*)::text as classes from attendance_acad
       where coalesce(teacher_id,'') <> '' and coalesce(student_id,'') <> ''
         and session_date >= $1::date and session_date < ($1::date + interval '1 month')
       group by teacher_id, student_id`,
      [monthStart],
    ),
    query<{ teacher_id: string; student_id: string }>(
      `select distinct teacher_id, student_id from attendance_acad
       where coalesce(teacher_id,'') <> '' and coalesce(student_id,'') <> ''`,
    ),
    query<{ id: string; student_id: string | null; amount: string; branch: string | null }>(
      `select id, student_id, amount, branch from receipts
       where status <> 'VOID' and created_at >= $1::date and created_at < ($1::date + interval '1 month')`,
      [monthStart],
    ),
    query<{ teacher_id: string; payout_type: string; percentage: string }>(
      `select distinct on (teacher_id) teacher_id, payout_type, percentage from payout_rules order by teacher_id, id`,
    ),
    query<{ teacher_id: string; paid: string; payments: string }>(
      `select teacher_id, sum(amount)::text as paid, count(*)::text as payments
       from teacher_payouts where service_month = $1 group by teacher_id`,
      [month],
    ),
    query<{ student_id: string; teacher_id: string; amount: string }>(
      `select student_id, teacher_id, amount from payout_attributions where service_month = $1`,
      [month],
    ),
    query<{ id: string; name: string }>(`select id, name from students_acad`),
  ]);
  const paidOf = new Map(paidRows.map((r) => [r.teacher_id, { paid: n(r.paid), payments: Number(r.payments) || 0 }]));
  const nameOf = new Map(studentNames.map((r) => [r.id, r.name]));

  // Teachers of a student, preferring the ones who taught them in the month.
  const monthTeachers = new Map<string, Map<string, number>>();
  for (const l of monthLinks) {
    if (!monthTeachers.has(l.student_id)) monthTeachers.set(l.student_id, new Map());
    monthTeachers.get(l.student_id)!.set(l.teacher_id, Number(l.classes) || 0);
  }
  const everTeachers = new Map<string, Set<string>>();
  for (const l of links) {
    if (!everTeachers.has(l.student_id)) everTeachers.set(l.student_id, new Set());
    everTeachers.get(l.student_id)!.add(l.teacher_id);
  }
  const teachersOf = (sid: string): string[] => {
    const inMonth = monthTeachers.get(sid);
    if (inMonth?.size) return [...inMonth.keys()];
    return [...(everTeachers.get(sid) ?? [])];
  };
  const ruleOf = new Map(rules.map((r) => [r.teacher_id, r]));

  const byStudent = new Map<string, { amount: number; count: number }>();
  let unattributed = 0;
  let unattributedAmount = 0;
  for (const r of receipts) {
    const sid = s(r.student_id);
    if (!sid) {
      unattributed++;
      unattributedAmount += n(r.amount);
      continue;
    }
    const cur = byStudent.get(sid) ?? { amount: 0, count: 0 };
    cur.amount += n(r.amount);
    cur.count += 1;
    byStudent.set(sid, cur);
  }

  // Founder decisions for shared students this month.
  const decided = new Map<string, Map<string, number>>();
  for (const a of attributions) {
    if (!decided.has(a.student_id)) decided.set(a.student_id, new Map());
    decided.get(a.student_id)!.set(a.teacher_id, n(a.amount));
  }

  // Split each paying student's fee into per-teacher credit.
  const creditOf = new Map<string, { amount: number; count: number }>();
  const credit = (tid: string, amount: number, count: number) => {
    const cur = creditOf.get(tid) ?? { amount: 0, count: 0 };
    cur.amount += amount;
    cur.count += count;
    creditOf.set(tid, cur);
  };
  const sharedOf = new Map<string, number>();
  const awaitingDecision: Record<string, unknown>[] = [];

  for (const [sid, agg] of byStudent) {
    const tids = teachersOf(sid);
    if (tids.length === 0) {
      unattributed++;
      unattributedAmount += agg.amount;
      continue;
    }
    if (tids.length === 1) {
      credit(tids[0], agg.amount, agg.count);
      continue;
    }
    // Shared: only what the founder has assigned counts for anybody.
    const decision = decided.get(sid);
    let assigned = 0;
    for (const tid of tids) {
      const share = money(decision?.get(tid) ?? 0);
      if (share <= 0) continue;
      credit(tid, share, 0);
      assigned += share;
      sharedOf.set(tid, (sharedOf.get(tid) ?? 0) + 1);
    }
    const remaining = money(agg.amount - assigned);
    if (remaining > 0.005) {
      const classes = monthTeachers.get(sid);
      awaitingDecision.push({
        studentId: sid,
        studentName: nameOf.get(sid) ?? sid,
        collected: money(agg.amount),
        assigned: money(assigned),
        remaining,
        receiptCount: agg.count,
        teachers: tids.map((tid) => ({
          teacherId: tid,
          teacherName: teachers.find((t) => t.id === tid)?.name ?? tid,
          classesThisMonth: classes?.get(tid) ?? 0,
          assigned: money(decision?.get(tid) ?? 0),
        })),
      });
    }
  }

  const results = teachers.map((t) => {
    const rule = ruleOf.get(t.id);
    const pct = n(rule?.percentage);
    const own = creditOf.get(t.id) ?? { amount: 0, count: 0 };
    const totalCollection = money(own.amount);
    const receiptCount = own.count;
    const sharedStudents = sharedOf.get(t.id) ?? 0;
    const share = money(totalCollection * (pct / 100));
    const settled = paidOf.get(t.id) ?? { paid: 0, payments: 0 };
    return {
      teacherId: t.id,
      teacherName: t.name,
      month,
      entityId: "ENT-KANDIVALI",
      receiptCount,
      totalCollection,
      sharePercent: pct,
      // Shared students already decided by the founder and included above.
      sharedStudentsAssigned: sharedStudents,
      totalTeacherShare: share,
      payable: share,
      alreadyPaid: money(settled.paid),
      balance: payoutBalance(share, settled.paid),
      paymentCount: settled.payments,
      status: payoutStatus(share, settled.paid),
      missingRule: rule == null,
      preCutover: false,
      note: rule == null ? "No payout rule set for this teacher" : "",
    };
  });

  return ok({
    results,
    month,
    // Receipts inside the month that carry no student link (older rows), so
    // the totals above can be reconciled against the cashbook.
    unattributedReceipts: unattributed,
    unattributedAmount,
    // Students taught by more than one teacher this month. Their fee counts
    // for NOBODY until the founder assigns it (api_assignSharedStudent), so
    // the payout totals never exceed the money actually collected.
    awaitingDecision,
    awaitingDecisionAmount: money(awaitingDecision.reduce((a, r) => a + Number(r.remaining), 0)),
    note: "payout preview computed from receipts in the month, one receipt counted once",
  });
}

/**
 * Record money actually paid to a teacher for a service month. Writes the
 * payout and a matching cashbook outflow in one transaction, so the ledger
 * and the payout history can never disagree.
 */
async function recordTeacherPayout(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const teacherId = s(arg["teacherId"]);
  const amount = n(arg["amount"]);
  const month = s(arg["month"] ?? arg["serviceMonth"]);
  if (!teacherId) return { ok: false, code: "NO_TEACHER", error: "teacherId required" };
  if (!isServiceMonth(month)) return { ok: false, code: "BAD_MONTH", error: "month must be YYYY-MM" };
  if (amount <= 0) return { ok: false, code: "BAD_AMOUNT", error: "Amount must be > 0" };

  const teacher = await acadTeacherById(teacherId);
  if (!teacher) return { ok: false, code: "NOT_FOUND", error: `No teacher ${teacherId}` };

  const branch = defaultBranch(scope, arg["branch"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  const paidOn = d(s(arg["paidOn"] ?? arg["date"])) || todayIso();
  const mode = s(arg["paymentMode"]) || "Bank Transfer";
  const reference = s(arg["reference"] ?? arg["note"]);
  const id = newId("TPO");
  const ledgerId = newId("LED");

  await withTransaction(async (tx) => {
    await tx.query(
      `insert into money_ledger (id, entry_date, party_name, category, description, outflow, amount, payment_mode, status, branch)
       values ($1, $2::date, $3, 'Teacher Payout', $4, $5, $5, $6, 'ACTIVE', $7)`,
      [ledgerId, paidOn, teacher.name, `Payout ${month}${reference ? ` · ${reference}` : ""}`, amount, mode, branch],
    );
    await tx.query(
      `insert into teacher_payouts (id, teacher_id, teacher_name, service_month, amount, paid_on, payment_mode, reference, branch, recorded_by, ledger_id)
       values ($1,$2,$3,$4,$5,$6::date,$7,$8,$9,$10,$11)`,
      [id, teacherId, teacher.name, month, amount, paidOn, mode, reference || null, branch, s(arg["recordedBy"]) || "founder", ledgerId],
    );
  });
  await bumpRevisions(["payouts", "expenses", "teachers", "dashboard"]);

  const totals = await queryOne<{ paid: string }>(
    `select coalesce(sum(amount),0)::text as paid from teacher_payouts where teacher_id = $1 and service_month = $2`,
    [teacherId, month],
  );
  return ok({
    payoutId: id,
    teacherId,
    teacherName: teacher.name,
    month,
    amount: money(amount),
    paidOn,
    paymentMode: mode,
    totalPaidForMonth: money(n(totals?.paid)),
    ledgerId,
    note: "payout recorded and posted to the cashbook",
  });
}

/**
 * Record the founder's decision on how a shared student's fee splits between
 * the teachers who taught them that month. Replaces any previous decision for
 * that student and month. The total may not exceed what the student actually
 * paid in the month.
 */
async function assignSharedStudent(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const month = s(arg["month"]);
  const studentId = s(arg["studentId"]);
  if (!isServiceMonth(month)) return { ok: false, code: "BAD_MONTH", error: "month must be YYYY-MM" };
  if (!studentId) return { ok: false, code: "NO_STUDENT", error: "studentId required" };

  const raw = Array.isArray(arg["allocations"]) ? (arg["allocations"] as Record<string, unknown>[]) : [];
  const allocations = raw
    .map((a) => ({ teacherId: s(a["teacherId"]), amount: money(n(a["amount"])) }))
    .filter((a) => a.teacherId && a.amount > 0);

  const student = await acadStudentById(studentId);
  if (!student) return { ok: false, code: "NOT_FOUND", error: `No student ${studentId}` };

  const monthStart = `${month}-01`;
  const collectedRow = await queryOne<{ total: string }>(
    `select coalesce(sum(amount),0)::text as total from receipts
     where student_id = $1 and status <> 'VOID'
       and created_at >= $2::date and created_at < ($2::date + interval '1 month')`,
    [studentId, monthStart],
  );
  const collected = money(n(collectedRow?.total));
  const total = money(allocations.reduce((a, x) => a + x.amount, 0));
  if (total > collected + 0.005) {
    return {
      ok: false,
      code: "OVER_ALLOCATED",
      error: `Allocated ${total} but the student paid ${collected} in ${month}`,
    };
  }
  for (const a of allocations) {
    if (!(await acadTeacherById(a.teacherId))) {
      return { ok: false, code: "NOT_FOUND", error: `No teacher ${a.teacherId}` };
    }
  }

  await withTransaction(async (tx) => {
    await tx.query(`delete from payout_attributions where service_month = $1 and student_id = $2`, [month, studentId]);
    for (const a of allocations) {
      await tx.query(
        `insert into payout_attributions (id, service_month, student_id, teacher_id, amount, decided_by)
         values ($1,$2,$3,$4,$5,$6)`,
        [newId("PATT"), month, studentId, a.teacherId, a.amount, s(arg["decidedBy"]) || "founder"],
      );
    }
  });
  await bumpRevisions(["payouts", "dashboard"]);

  return ok({
    month,
    studentId,
    studentName: student.name,
    collected,
    assigned: total,
    remaining: money(collected - total),
    allocations,
    note: allocations.length ? "split recorded" : "split cleared",
  });
}

/** Payments already made, newest first. Optionally for one teacher/month. */
async function payoutHistory(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const teacherId = s(arg["teacherId"]);
  const month = s(arg["month"]);
  const where: string[] = [];
  const params: unknown[] = [];
  if (teacherId) {
    params.push(teacherId);
    where.push(`teacher_id = $${params.length}`);
  }
  if (isServiceMonth(month)) {
    params.push(month);
    where.push(`service_month = $${params.length}`);
  }
  const rows = await query<Record<string, unknown>>(
    `select id, teacher_id, teacher_name, service_month, amount, paid_on::text, payment_mode, reference, branch, recorded_by
     from teacher_payouts ${where.length ? `where ${where.join(" and ")}` : ""}
     order by paid_on desc, id desc limit 200`,
    params,
  );
  return ok({
    rows: rows.map((r) => ({
      payoutId: s(r.id),
      teacherId: s(r.teacher_id),
      teacherName: s(r.teacher_name),
      month: s(r.service_month),
      amount: n(r.amount),
      paidOn: d(r.paid_on),
      paymentMode: s(r.payment_mode),
      reference: s(r.reference),
      branch: s(r.branch),
      recordedBy: s(r.recorded_by),
    })),
    total: money(rows.reduce((a, r) => a + n(r.amount), 0)),
  });
}

// ------------------------------------------------------- cashbook / expenses
async function cashbook(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const rows = (
    await query<Record<string, unknown>>(
      `select id as entry_id, entry_date::text, category, description, inflow, outflow, amount, payment_mode, status, branch from money_ledger order by entry_date desc limit 200`,
    )
  ).filter((r) => moneyInScope(scope, r.branch));
  const entries = rows.map((r) => ({
    entryId: s(r.entry_id),
    date: d(r.entry_date),
    category: s(r.category) || "Student Fees",
    description: s(r.description),
    amount: n(r.inflow) > 0 ? n(r.inflow) : n(r.outflow),
    type: n(r.inflow) > 0 ? "INFLOW" : "EXPENSE",
    mode: s(r.payment_mode),
    approvalStatus: s(r.status) === "ACTIVE" ? "APPROVED" : s(r.status),
    status: s(r.status),
  }));
  return ok({ entries });
}

async function addExpense(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const amount = n(arg["amount"]);
  const desc = s(arg["description"] ?? arg["narrative"]);
  if (amount <= 0 || !desc) return { ok: false, code: "BAD_EXPENSE", error: "valid amount + description required" };
  const id = newId("EXP");
  await withTransaction(async (tx) => {
    await tx.query(
      `insert into expenses (id, expense_date, category, vendor, description, amount, approval_status)
       values ($1, now(), $2, $3, $4, $5, 'APPROVED')`,
      [id, s(arg["category"]) || "General", s(arg["vendor"] ?? arg["payee"]), desc, amount],
    );
    await tx.query(
      `insert into money_ledger (id, entry_date, party_name, category, description, outflow, amount, payment_mode, status)
       values ($1, now(), $2, $3, $4, $5, $5, $6, 'ACTIVE')`,
      [newId("LED"), s(arg["vendor"] ?? arg["payee"]) || "Office", s(arg["category"]) || "General", desc, amount, s(arg["paymentMode"] ?? "Cash")],
    );
  });
  await bumpRevisions(["expenses", "dashboard"]);
  return ok({ entryId: id, expenseDraftId: newId("EDRAFT"), note: "expense recorded" });
}

/**
 * Staff submit an expense for the founder to approve. This used to return
 * "persisted: true" without writing anything, so the entry was lost.
 */
async function submitExpenseDraft(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const amount = n(arg["amount"]);
  const description = s(arg["description"] ?? arg["narrative"]);
  if (amount <= 0 || !description) {
    return { ok: false, code: "BAD_EXPENSE", error: "valid amount + description required" };
  }
  const branch = defaultBranch(scope, arg["branch"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  const id = newId("EDRAFT");
  await query(
    `insert into expense_drafts (id, status, category, vendor, description, amount, payment_mode, branch, submitted_by)
     values ($1,'SUBMITTED',$2,$3,$4,$5,$6,$7,$8)`,
    [
      id,
      s(arg["category"]) || "General",
      s(arg["vendor"] ?? arg["payee"]),
      description,
      amount,
      s(arg["paymentMode"]) || "Cash",
      branch,
      s(arg["submittedBy"]) || "staff",
    ],
  );
  await bumpRevisions(["expenses", "approvals", "tasks"]);
  return ok({ draftId: id, persisted: true, status: "SUBMITTED", note: "expense draft submitted for approval" });
}

/** Founder approves: the draft becomes a real expense plus a cashbook outflow. */
async function expenseDraftApprove(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const draftId = s(arg["draftId"] ?? arg["itemId"]);
  if (!draftId) return { ok: false, code: "NO_DRAFT", error: "draftId required" };
  const result: Record<string, unknown> = await withTransaction(async (tx) => {
    const draft = await tx.queryOne<Record<string, unknown>>(
      `select * from expense_drafts where id = $1 for update`,
      [draftId],
    );
    if (!draft) return { ok: false, code: "NOT_FOUND", error: `No expense draft ${draftId}` };
    if (s(draft.status) === "APPROVED") {
      return ok({ changed: false, draftId, status: "APPROVED", expenseId: s(draft.expense_id), idempotent: true, note: "already approved" });
    }
    if (s(draft.status) !== "SUBMITTED") {
      return { ok: false, code: "NOT_SUBMITTED", error: `Draft status ${s(draft.status)}` };
    }
    const expenseId = newId("EXP");
    const ledgerId = newId("LED");
    const amount = n(draft.amount);
    await tx.query(
      `insert into expenses (id, expense_date, category, vendor, description, amount, approval_status)
       values ($1, now(), $2, $3, $4, $5, 'APPROVED')`,
      [expenseId, s(draft.category) || "General", s(draft.vendor), s(draft.description), amount],
    );
    await tx.query(
      `insert into money_ledger (id, entry_date, party_name, category, description, outflow, amount, payment_mode, status, branch)
       values ($1, now(), $2, $3, $4, $5, $5, $6, 'ACTIVE', $7)`,
      [ledgerId, s(draft.vendor) || "Office", s(draft.category) || "General", s(draft.description), amount, s(draft.payment_mode) || "Cash", s(draft.branch) || null],
    );
    await tx.query(
      `update expense_drafts set status = 'APPROVED', decided_by = $2, decided_at = now(), expense_id = $3, ledger_id = $4 where id = $1`,
      [draftId, s(arg["decidedBy"]) || "founder", expenseId, ledgerId],
    );
    return ok({ changed: true, draftId, status: "APPROVED", expenseId, ledgerId, amount, note: "expense recorded and posted to the cashbook" });
  });
  if (result["ok"] === true && result["changed"] === true) {
    await bumpRevisions(["expenses", "approvals", "dashboard"]);
  }
  return result;
}

async function expenseDraftReject(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const draftId = s(arg["draftId"] ?? arg["itemId"]);
  const reason = s(arg["reason"] ?? arg["comment"]);
  if (!draftId) return { ok: false, code: "NO_DRAFT", error: "draftId required" };
  const rows = await query<{ id: string }>(
    `update expense_drafts set status = 'REJECTED', decided_by = $2, decided_at = now(), decision_note = $3
     where id = $1 and status = 'SUBMITTED' returning id`,
    [draftId, s(arg["decidedBy"]) || "founder", reason || null],
  );
  if (!rows.length) return { ok: false, code: "NOT_FOUND", error: `No pending expense draft ${draftId}` };
  await bumpRevisions(["expenses", "approvals"]);
  return ok({ changed: true, draftId, status: "REJECTED", note: reason || "rejected" });
}

// ------------------------------------------------------- school invoices
async function generateSchoolInvoice(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const amount = n(arg["amount"]);
  if (amount <= 0) return { ok: false, code: "BAD_AMOUNT", error: "amount required" };
  const branch = defaultBranch(scope, arg["branch"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  const id = newId("SINV");
  const invoiceDate = s(arg["invoiceDate"]) || new Date().toISOString().slice(0, 10);
  const no = await withTransaction(async (tx) => {
    const docNo = await nextDocNo(tx, "schoolInvoice", schoolInvoiceSeries(new Date(invoiceDate)));
    await tx.query(
      `insert into school_invoices_rpc (id, invoice_no, invoice_date, branch, class_name, amount, tenure, status)
       values ($1,$2,$3,$4,$5,$6,$7,'FINAL')`,
      [id, docNo, invoiceDate, branch, s(arg["className"]), amount, s(arg["tenure"])],
    );
    return docNo;
  });
  await bumpRevisions(["invoices", "dashboard"]);
  return ok({
    invoiceId: id,
    invoiceNo: no,
    invoiceDate,
    branch,
    className: s(arg["className"]),
    amount,
    tenure: s(arg["tenure"]),
    owner1: { name: "Sharvil Vaidya", id: "OWNER-1", signatureUrl: "", title: "Owner 1" },
    owner2: { name: "Piyush Kashyap", id: "OWNER-2", signatureUrl: "", title: "Owner 2" },
    pdfUrl: "",
  });
}

async function listSchoolInvoices(scope: BranchScope): Promise<Record<string, unknown>> {
  const rows = (
    await query<Record<string, unknown>>(`select id, invoice_no, invoice_date, branch, class_name, amount, tenure, status from school_invoices_rpc order by id desc`)
  ).filter((r) => inScope(scope, r.branch));
  return ok({
    invoices: rows.map((r) => ({
      invoiceId: s(r.id),
      invoiceNo: s(r.invoice_no),
      invoiceDate: s(r.invoice_date),
      branch: s(r.branch),
      className: s(r.class_name),
      amount: n(r.amount),
      tenure: s(r.tenure),
      status: s(r.status),
    })),
  });
}

async function getSchoolInvoice(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const id = s(arg["invoiceId"]);
  const r = await queryOne<Record<string, unknown>>(`select * from school_invoices_rpc where id = $1`, [id]);
  if (!r) return { ok: false, code: "NOT_FOUND", error: `No invoice ${id}` };
  if (!inScope(scope, r.branch)) return branchForbidden(recordBranch(r.branch));
  return ok({
    invoice: {
      invoiceId: s(r.id),
      invoiceNo: s(r.invoice_no),
      invoiceDate: s(r.invoice_date),
      branch: s(r.branch),
      className: s(r.class_name),
      amount: n(r.amount),
      tenure: s(r.tenure),
      pdfUrl: "",
      owner1: { name: "Sharvil Vaidya", id: "OWNER-1", signatureUrl: "", title: "Owner 1" },
      owner2: { name: "Piyush Kashyap", id: "OWNER-2", signatureUrl: "", title: "Owner 2" },
    },
  });
}

// -------------------------------------------------------------- timetable
function ttSlot(seed: string, day: number): { start: string; end: string } {
  let h = 10;
  for (const ch of seed + "-" + day) h = (h * 31 + ch.codePointAt(0)!) % 10 + 10;
  const start = `${String(h).padStart(2, "0")}:00`;
  const end = `${String(h + 1).padStart(2, "0")}:00`;
  return { start, end };
}

async function timetableList(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const branch = s(arg["branch"] ?? "ALL").toUpperCase();
  const visible = (rows: Record<string, unknown>[]) =>
    rows.filter((r) => inScope(scope, r.branch) && matchesRequestedBranch(branch, r.branch));
  let rows = visible(
    await query<Record<string, unknown>>(
      `select id, branch, day_of_week, start_time, end_time, class_name, teacher_id, teacher_name, status from timetable order by day_of_week, start_time`,
    ),
  );
  if (!rows.length) {
    // seed from attendance-derived classes (real schedule)
    const cls = await query<Record<string, unknown>>(
      `select distinct teacher_id, teacher_name, instrument from attendance_acad where teacher_id <> '' order by instrument`,
    );
    const seeded: Record<string, unknown>[] = [];
    for (const c of cls) {
      for (let day = 0; day < 7; day++) {
        const time = ttSlot(s(c.teacher_id) || s(c.instrument) || "x", day);
        seeded.push({
          id: `TT-${c.teacher_id}-${day}`,
          branch: "KANDIVALI",
          day_of_week: day,
          start_time: time.start,
          end_time: time.end,
          class_name: s(c.instrument) || "Music",
          teacher_id: s(c.teacher_id),
          teacher_name: s(c.teacher_name),
          status: "ENABLED",
        });
      }
    }
    for (const e of seeded) {
      await query(
        `insert into timetable (id, branch, day_of_week, start_time, end_time, class_name, teacher_id, teacher_name, status)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9) on conflict (id) do nothing`,
        [e.id, e.branch, e.day_of_week, e.start_time, e.end_time, e.class_name, e.teacher_id, e.teacher_name, e.status],
      );
    }
    rows = visible(
      await query<Record<string, unknown>>(
        `select id, branch, day_of_week, start_time, end_time, class_name, teacher_id, teacher_name, status from timetable order by day_of_week, start_time`,
      ),
    );
  }
  return ok({
    entries: rows.map((r) => ({
      id: s(r.id),
      branch: s(r.branch),
      dayOfWeek: n(r.day_of_week),
      startTime: s(r.start_time),
      endTime: s(r.end_time),
      className: s(r.class_name),
      teacherId: s(r.teacher_id),
      teacherName: s(r.teacher_name),
      status: s(r.status),
    })),
    seeded: rows.length > 0,
    note: "standalone timetable",
  });
}

async function timetableCreate(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const branch = defaultBranch(scope, arg["branch"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  const id = newId("TT");
  await query(
    `insert into timetable (id, branch, day_of_week, start_time, end_time, class_name, teacher_id, teacher_name, status)
     values ($1,$2,$3,$4,$5,$6,$7,$8,$9) on conflict (id) do nothing`,
    [id, branch, n(arg["dayOfWeek"]), s(arg["startTime"]), s(arg["endTime"]), s(arg["className"]), s(arg["teacherId"]), s(arg["teacherName"]), s(arg["status"]).toUpperCase() || "ENABLED"],
  );
  await bumpRevisions(["timetable", "sessions"]);
  return ok({ entry: { id, branch, dayOfWeek: n(arg["dayOfWeek"]), startTime: s(arg["startTime"]), endTime: s(arg["endTime"]), className: s(arg["className"]), teacherId: s(arg["teacherId"]), teacherName: s(arg["teacherName"]), status: s(arg["status"]).toUpperCase() || "ENABLED" }, note: "created" });
}

async function timetableUpdate(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const id = s(arg["id"]);
  const cur = await queryOne<Record<string, unknown>>(`select * from timetable where id = $1`, [id]);
  if (!cur) return { ok: false, code: "TT_ENTRY_NOT_FOUND", error: "Entry not found." };
  // Both the current branch and the requested one must be in scope.
  if (!inScope(scope, cur.branch)) return branchForbidden(recordBranch(cur.branch));
  const nextBranch = recordBranch(s(arg["branch"] ?? cur.branch));
  if (!inScope(scope, nextBranch)) return branchForbidden(nextBranch);
  await query(
    `update timetable set branch=$2, day_of_week=$3, start_time=$4, end_time=$5, class_name=$6, teacher_id=$7, teacher_name=$8, status=$9 where id=$1`,
    [id, nextBranch, n(arg["dayOfWeek"] ?? cur.day_of_week), s(arg["startTime"] ?? cur.start_time), s(arg["endTime"] ?? cur.end_time), s(arg["className"] ?? cur.class_name), s(arg["teacherId"] ?? cur.teacher_id), s(arg["teacherName"] ?? cur.teacher_name), s(arg["status"] ?? cur.status).toUpperCase()],
  );
  await bumpRevisions(["timetable", "sessions"]);
  return ok({ entry: { ...cur, ...arg, id }, note: "updated" });
}

async function timetableDelete(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const id = s(arg["id"]);
  const before = await queryOne<{ id: string; branch: string }>(`select id, branch from timetable where id = $1`, [id]);
  if (before && !inScope(scope, before.branch)) return branchForbidden(recordBranch(before.branch));
  if (before) await query(`delete from timetable where id = $1`, [id]);
  if (before) await bumpRevisions(["timetable", "sessions"]);
  return ok({ deleted: before != null, note: "deleted" });
}

// -------------------------------------------------------- attendance / today
async function attendanceRoster(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const instrument = s(arg["instrument"]).trim();
  const students = (await acadStudents()).filter(
    (x) => s(x.status).toUpperCase() === "ACTIVE" && inScope(scope, x.branch) && matchesRequestedBranch(arg["branch"], x.branch),
  );
  const rows = instrument ? students.filter((x) => s(x.instrument).toUpperCase() === instrument.toUpperCase()) : students;
  const instruments = Array.from(new Set(students.map((x) => s(x.instrument)).filter(Boolean)));
  return ok({
    date: d(s(arg["date"])) || new Date().toISOString().slice(0, 10),
    branch: s(arg["branch"] ?? "ALL"),
    count: rows.length,
    instruments,
    students: (await studentsToRpc(rows)).map((st, i) => ({
      studentId: st.studentId,
      name: st.studentName,
      instrument: st.instrument,
      teacherId: st.teacherId ?? "",
      teacherName: st.teacher,
      phone: s(rows[i].phone),
      expectedToday: true,
    })),
  });
}

async function markAttendance(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const rows = (arg["state"] ?? arg["marks"] ?? arg["rows"]) as Record<string, unknown> | undefined;
  const entries = Array.isArray(rows) ? rows : rows && typeof rows === "object" ? Object.entries(rows).map(([studentId, status]) => ({ studentId, status })) : [];
  const date = d(s(arg["workDate"] ?? arg["date"])) || new Date().toISOString().slice(0, 10);
  if (!scope.unrestricted) {
    // Reject the whole batch rather than writing part of another branch's roster.
    for (const e of entries) {
      const sid = s(e.studentId ?? e["studentId"]);
      if (!sid) continue;
      const student = await acadStudentById(sid);
      if (!student || !inScope(scope, student.branch)) return branchForbidden(recordBranch(student?.branch));
    }
  }
  let count = 0;
  for (const e of entries) {
    const sid = s(e.studentId ?? e["studentId"]);
    const status = s(e.status ?? e["status"]);
    if (!sid || !status) continue;
    // student_name used to be filled with the id, which broke every later
    // lookup that joins attendance by name.
    const student = await acadStudentById(sid);
    const teacher = await queryOne<{ teacher_id: string; teacher_name: string }>(
      `select teacher_id, teacher_name from attendance_acad
       where student_id = $1 and coalesce(teacher_id,'') <> '' order by session_date desc limit 1`,
      [sid],
    );
    const id = newId(`ATT-${sid}-${date}`);
    await query(
      `insert into attendance_acad (id, session_date, student_id, student_name, teacher_id, teacher_name, instrument, status)
       values ($1,$2,$3,$4,$5,$6,$7,$8) on conflict (id) do nothing`,
      [id, date, sid, s(student?.name) || sid, s(teacher?.teacher_id), s(teacher?.teacher_name), s(student?.instrument), status.toUpperCase()],
    );
    count++;
  }
  await bumpRevisions(["attendance", "sessions", "tasks", "dashboard"]);
  return ok({ action: "CREATED", attendanceId: newId(`ATT-${date}`), state: entries, workDate: date, marked: count });
}

async function todaysTasks(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  // Every count below is real: no placeholder numbers.
  const { by, today } = await dueBuckets(scope);
  const inquiries = (
    await query<{ branch: string; status: string }>(`select branch, status from inquiries`)
  ).filter((r) => inScope(scope, r.branch) && !["CONVERTED", "LOST", "CLOSED"].includes(s(r.status).toUpperCase()));
  const drafts = (
    await query<{ branch: string }>(`select branch from payment_drafts where status = 'SUBMITTED'`)
  ).filter((r) => inScope(scope, r.branch));

  const state = (n: number) => (n > 0 ? "ATTENTION" : "OPEN");
  const cards = [
    { key: "FEES_OVERDUE", title: "Fees Overdue", label: "Fees Overdue", priority: "HIGH", count: by.OVERDUE.length, state: state(by.OVERDUE.length), targetView: "students", emptyText: "Nothing overdue", actionable: true, bucket: "OVERDUE" },
    { key: "FEES_DUE_TODAY", title: "Fees Due Today", label: "Fees Due Today", priority: "HIGH", count: by.DUE_TODAY.length, state: state(by.DUE_TODAY.length), targetView: "students", emptyText: "No fees due today", actionable: true, bucket: "DUE_TODAY" },
    { key: "FEES_DUE_SOON", title: "Fees Upcoming", label: "Fees Upcoming", priority: "MEDIUM", count: by.DUE_SOON.length, state: "OPEN", targetView: "students", emptyText: "Nothing upcoming", actionable: true, bucket: "DUE_SOON" },
    { key: "PAYMENT_PENDING", title: "Payment Pending", label: "Payment Pending", priority: "HIGH", count: drafts.length, state: state(drafts.length), targetView: "students", emptyText: "No pending payments", actionable: true },
    { key: "INQUIRIES_FOLLOW_UP", title: "Inquiries to follow up", label: "Inquiries to follow up", priority: "MEDIUM", count: inquiries.length, state: "OPEN", targetView: "inquiries", emptyText: "No inquiries", actionable: true },
    { key: "FEE_PLAN_MISSING", title: "Fee plan not set", label: "Fee plan not set", priority: "LOW", count: by.UNKNOWN.length, state: "OPEN", targetView: "students", emptyText: "Every student has a plan", actionable: true, bucket: "UNKNOWN" },
  ];
  return ok({ cards, mode: "COPY_ONLY", today });
}

async function todaysClasses(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const date = d(s(arg["date"])) || new Date().toISOString().slice(0, 10);
  const branch = s(arg["branch"] ?? "ALL");
  const tt = (await query<Record<string, unknown>>(`select * from timetable where status = 'ENABLED'`)).filter((r) => inScope(scope, r.branch));
  const rows = tt.map((r, i) => ({
    eventId: `E-${date}-${i + 1}`,
    classDate: date,
    startTime: s(r.start_time),
    teacherId: s(r.teacher_id),
    teacherName: s(r.teacher_name),
    branch: s(r.branch),
    course: s(r.class_name),
    outcome: "",
    deliveredBy: "",
    payeeTeacherId: "",
    entryDate: "",
    recordedBy: "",
    evidenceClass: "",
    evidenceReason: "",
    notRequired: false,
    closureId: "",
    closureReason: "",
    customKind: "",
    customReason: "",
    resolved: false,
    answerable: true,
  }));
  const filtered = branch === "ALL" ? rows : rows.filter((r) => s(r.branch).toUpperCase() === branch.toUpperCase());
  return ok({ date, count: filtered.length, unanswered: filtered.length, outcomes: ["HELD", "TEACHER_CANCELLED", "ACADEMY_CANCELLED", "SUBSTITUTE_DELIVERED", "RESCHEDULED"], rows: filtered, lateHours: 48 });
}

async function resolveTodaysClass(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const eventId = s(arg["eventId"]);
  const branch = defaultBranch(scope, arg["branch"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  const outcome = s(arg["outcome"]);
  const deliveredBy = s(arg["deliveredBy"]);
  // eventId is E-<yyyy-mm-dd>-<n>; splitting on "-" used to yield just "2026".
  const date = /^E-(\d{4}-\d{2}-\d{2})-\d+$/.exec(eventId)?.[1] ?? new Date().toISOString().slice(0, 10);
  await query(
    `insert into scheduled_sessions (id, session_date, start_time, teacher_id, teacher_name, branch, course, outcome, delivered_by, payee_teacher_id, recorded_by, evidence_class, evidence_reason, resolved, answerable)
     values ($1, $2, $3, $4, $5, $10, '', $6, $7, $7, $8, 'VERIFIED', $9, true, false)
     on conflict (id) do update set outcome = excluded.outcome, delivered_by = excluded.delivered_by, evidence_class = 'VERIFIED', resolved = true`,
    [eventId, date, s(arg["startTime"] ?? "17:00"), s(arg["teacherId"]), s(arg["teacherName"]), outcome, deliveredBy, s(arg["recordedBy"] ?? "latika@ops"), `outcome ${outcome} recorded`, branch],
  );
  await bumpRevisions(["sessions", "attendance", "tasks"]);
  return ok({ eventId, outcome, evidenceClass: "VERIFIED", payeeTeacherId: deliveredBy, note: "class resolved" });
}

/** Schedule a session. The id used to be returned without storing anything,
 *  so api_staff_sessionRoster could never find it again. */
async function scheduleSession(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const branch = defaultBranch(scope, arg["branch"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  const id = newId("SCSS");
  const sessionDate = d(s(arg["sessionDate"])) || todayIso();
  await query(
    `insert into scheduled_sessions (id, session_date, start_time, teacher_id, teacher_name, branch, course, resolved, answerable)
     values ($1,$2,$3,$4,$5,$6,$7,false,true)`,
    [id, sessionDate, s(arg["startTime"]), s(arg["teacherId"]), s(arg["teacherName"]), branch, s(arg["course"] ?? arg["className"])],
  );
  await bumpRevisions(["sessions", "tasks"]);
  return ok({
    scheduledSessionId: id,
    status: "SCHEDULED",
    sessionDate,
    branch,
    sessionCredit: n(arg["sessionCredit"]) || 1,
    durationMinutes: n(arg["durationMinutes"]) || 60,
  });
}

async function sessionRoster(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const tts = await query<Record<string, unknown>>(`select * from scheduled_sessions where id = $1`, [s(arg["scheduledSessionId"])]);
  const session = tts[0];
  const branch = s(session?.branch ?? "KANDIVALI");
  if (session && !inScope(scope, session.branch)) return branchForbidden(recordBranch(session.branch));
  const all = (await acadStudents()).filter(
    (x) => s(x.status).toUpperCase() === "ACTIVE" && inScope(scope, x.branch) && matchesRequestedBranch(branch, x.branch),
  );
  const rows = (await studentsToRpc(all.slice(0, 30))).map((st) => ({
    studentId: st.studentId,
    name: st.studentName,
    instrument: st.instrument,
    state: "NOT_MARKED",
    teacherId: st.teacherId ?? "",
    teacherName: st.teacher,
  }));
  return ok({ scheduledSessionId: s(arg["scheduledSessionId"]), status: "OPEN", closed: false, unanswered: true, sessionDate: s(session?.session_date) || new Date().toISOString().slice(0, 10), sessionCredit: 1, total: rows.length, present: 0, absent: 0, excused: 0, notMarked: rows.length, rows, note: "standalone roster" });
}

async function feeDueList(scope: BranchScope): Promise<Record<string, unknown>> {
  const { by } = await dueBuckets(scope);
  const pending = (
    await query<{ branch: string }>(`select branch from payment_drafts where status = 'SUBMITTED'`)
  ).filter((r) => inScope(scope, r.branch));
  return ok({
    counts: {
      dueToday: by.DUE_TODAY.length,
      dueSoon: by.DUE_SOON.length,
      overdue: by.OVERDUE.length,
      notRecorded: by.UNKNOWN.length,
      paymentPending: pending.length,
    },
  });
}

// -------------------------------------------------------------- inquiries
async function inquiryQueue(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const branch = s(arg["branch"] ?? "ALL");
  const rows = await query<Record<string, unknown>>(`select id, name, phone, instrument, branch, source, notes, status, created_at::text from inquiries order by id desc limit 100`);
  const filtered = rows.filter((r) => inScope(scope, r.branch) && matchesRequestedBranch(branch, r.branch));
  return ok({
    rows: filtered.map((r) => ({
      inquiry_id: s(r.id),
      name: s(r.name),
      phone: s(r.phone),
      instrument: s(r.instrument),
      branch: s(r.branch),
      status: s(r.status),
      next_contact_date: "",
      created_at: d(r.created_at),
    })),
  });
}

async function inquiryQuickAdd(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const name = s(arg["name"]).trim();
  if (!name) return { ok: false, code: "NO_NAME", error: "name required" };
  const branch = defaultBranch(scope, arg["branch"]);
  if (!inScope(scope, branch)) return branchForbidden(branch);
  const id = newId("INQ");
  await query(
    `insert into inquiries (id, name, phone, instrument, branch, source, notes, status) values ($1,$2,$3,$4,$5,$6,$7,'NEW') on conflict (id) do nothing`,
    [id, name, s(arg["phone"]), s(arg["instrument"] ?? arg["course"]), branch, s(arg["source"] ?? "Walk-in"), s(arg["notes"])],
  );
  await bumpRevisions(["inquiries", "tasks"]);
  return ok({ inquiryId: id, idempotent: false, note: "inquiry captured" });
}

async function inquiryTransition(arg: Record<string, unknown>, scope: BranchScope): Promise<Record<string, unknown>> {
  const id = s(arg["inquiryId"]);
  const action = s(arg["action"]);
  const cur = await queryOne<{ branch: string }>("select branch from inquiries where id = $1", [id]);
  if (!cur) return { ok: false, code: "NOT_FOUND", error: `No inquiry ${id}` };
  if (!inScope(scope, cur.branch)) return branchForbidden(recordBranch(cur.branch));
  await query("update inquiries set status = $1 where id = $2", [action === "LOG_CONTACT" ? "CONTACTED" : action === "SCHEDULE_TRIAL" ? "TRIAL_SCHEDULED" : action, id]);
  await bumpRevisions(["inquiries", "tasks"]);
  return ok({ inquiryId: id, action, after: { status: action === "LOG_CONTACT" ? "CONTACTED" : action === "SCHEDULE_TRIAL" ? "TRIAL_SCHEDULED" : action }, readBack: { ok: true }, auditWritten: true, note: "inquiry moved" });
}

// -------------------------------------------------------------- approvals
async function founderApprovals(): Promise<Record<string, unknown>> {
  const drafts = await query<Record<string, unknown>>(
    `select id, status, student_id, student_name, amount, payment_mode, branch, terms_status from payment_drafts where status <> 'FINALISED' order by submitted_at`,
  );
  const paymentItems = drafts.map((r) => ({
    type: "PAYMENT_DRAFT",
    itemId: s(r.id),
    entity: s(r.student_name),
    studentId: s(r.student_id),
    noStudentLinked: s(r.student_id) === "",
    paymentMode: s(r.payment_mode),
    feesPeriod: "",
    amount: s(r.amount),
    branch: s(r.branch),
    date: d(s(r.submitted_at ?? "")),
    reason: "payment approval",
    flags: { backdated: false, incomplete: false, junk: false },
    termsStatus: s(r.terms_status) || "TERMS ACCEPTED",
    actions: ["details", "approve", "reject"],
  }));
  const expenseRows = await query<Record<string, unknown>>(
    `select id, category, vendor, description, amount, payment_mode, branch, submitted_by, submitted_at::text
     from expense_drafts where status = 'SUBMITTED' order by submitted_at`,
  );
  const expenseItems = expenseRows.map((r) => ({
    type: "EXPENSE_DRAFT",
    itemId: s(r.id),
    entity: s(r.vendor) || s(r.category) || "Expense",
    studentId: "",
    noStudentLinked: false,
    paymentMode: s(r.payment_mode),
    feesPeriod: "",
    amount: s(r.amount),
    branch: s(r.branch),
    date: d(r.submitted_at),
    reason: s(r.description),
    flags: { backdated: false, incomplete: false, junk: false },
    termsStatus: "",
    actions: ["details", "approve", "reject"],
  }));

  const items = [...paymentItems, ...expenseItems];
  const groups = [
    { type: "PAYMENT_DRAFT", label: "Payment drafts", items: paymentItems },
    { type: "EXPENSE_DRAFT", label: "Expense drafts", items: expenseItems },
  ];
  return ok({
    build: "RC3.85-standalone",
    branch: "CONSOLIDATED",
    count: items.length,
    counts: {
      total: items.length,
      WAITING_ON_TERMS: 0,
      PAYMENT_DRAFT: paymentItems.length,
      EXPENSE_DRAFT: expenseItems.length,
      STUDENT_DRAFT: 0,
      SCHOOL_MASTER: 0,
      WAIVER: 0,
      UNKNOWN_STATUS: 0,
    },
    empty: items.length === 0,
    items,
    groups,
    note: "standalone approvals",
  });
}

/**
 * The write trail: who did what, newest first. Optionally filtered to one
 * function or to failures only. Rows hold ids, never names or amounts.
 */
async function auditLog(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const limit = Math.min(Math.max(n(arg["limit"]) || 100, 1), 500);
  const where: string[] = [];
  const params: unknown[] = [];
  const fn = s(arg["fn"]);
  if (fn) {
    params.push(fn);
    where.push(`fn = $${params.length}`);
  }
  if (arg["failuresOnly"] === true) where.push("ok = false");
  const days = n(arg["days"]);
  if (days > 0) {
    params.push(Math.round(days));
    where.push(`at >= now() - ($${params.length}::int * interval '1 day')`);
  }
  params.push(limit);

  const rows = await query<Record<string, unknown>>(
    `select at::text, actor_role, actor_email, device_label, fn, ok, code, branch, ref
     from audit_log ${where.length ? `where ${where.join(" and ")}` : ""}
     order by at desc limit $${params.length}`,
    params,
  );
  return ok({
    rows: rows.map((r) => ({
      at: s(r.at),
      actorRole: s(r.actor_role),
      actorEmail: s(r.actor_email),
      device: s(r.device_label),
      fn: s(r.fn),
      ok: r.ok === true,
      code: s(r.code),
      branch: s(r.branch),
      ref: s(r.ref),
    })),
    count: rows.length,
    note: "write trail — ids only, no names or amounts",
  });
}

async function staffMyRequests(scope: BranchScope): Promise<Record<string, unknown>> {
  const rows = (
    await query<Record<string, unknown>>(`select id, status, student_name, amount, branch, submitted_at::text from payment_drafts where status in ('SUBMITTED','APPROVED') order by submitted_at`)
  ).filter((r) => inScope(scope, r.branch));
  const expenseRows = (
    await query<Record<string, unknown>>(
      `select id, status, category, description, amount, branch, submitted_at::text
       from expense_drafts where status in ('SUBMITTED','APPROVED','REJECTED') order by submitted_at desc limit 100`,
    )
  ).filter((r) => inScope(scope, r.branch));

  const out = [
    ...rows.map((r) => ({
      type: "PAYMENT_DRAFT",
      id: s(r.id),
      status: s(r.status),
      student: s(r.student_name),
      category: "",
      amount: s(r.amount),
      when: d(r.submitted_at),
      backdated: false,
    })),
    ...expenseRows.map((r) => ({
      type: "EXPENSE_DRAFT",
      id: s(r.id),
      status: s(r.status),
      student: "",
      category: s(r.category),
      amount: s(r.amount),
      when: d(r.submitted_at),
      backdated: false,
    })),
  ];
  return ok({ branch: "ALL", count: out.length, rows: out, canApprove: false, note: "standalone my requests" });
}

// -------------------------------------------------------------- comm / sync
async function commGenerate(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const type = s(arg["type"] ?? "FEE_REMINDER").toUpperCase();
  const studentName = s(arg["studentName"] ?? "Student");
  const amount = s(arg["amount"] ?? "");
  return ok({
    type,
    subject: `Fees due — Swar Mangal`,
    body: `Namaste, reminder that ${studentName}'s fees of ${amount} are due. Please pay at your convenience. — SwarMangal Music Academy`,
    recipientName: `Parent of ${studentName}`,
    recipientType: "parent",
    typeRequested: s(arg["type"] ?? "FEE_REMINDER"),
    typeResolved: type,
    typeCorrected: false,
    typeNote: "",
    warnings: [],
    mode: "COPY_ONLY",
    providerSend: "DISABLED",
    termsLink: "",
    termsTokenId: "",
    termsTokenMinted: false,
    termsAuditIncomplete: false,
  });
}

async function syncChanges(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const known = (arg["knownRevisions"] as Record<string, number>) ?? {};
  // Live counters: every write handler bumps the entities it touched, so a
  // client only reloads what actually changed (this used to be a constant,
  // which meant no change was ever advertised).
  const revisions = await currentRevisions();
  const changes = Object.keys(revisions)
    .filter((k) => Number(known[k] ?? 0) !== revisions[k])
    .map((k) => ({ entity: k.toUpperCase(), operation: "UPDATED", id: "" }));
  return ok({ revisions, changes, note: "standalone sync" });
}

export { ok };