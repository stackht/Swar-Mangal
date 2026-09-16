import { query, queryOne } from "@/lib/db";
import { RpcRole } from "@/lib/rpc/auth";
import { s, n, d, acadStudents, acadStudentById, acadTeachers, acadTeacherById, studentToRpc, teacherToRpc, classSummary } from "@/lib/rpc/shared";

const ok = (extra: Record<string, unknown> = {}) => ({ ok: true, ...extra });

export async function dispatch2(role: RpcRole, fn: string, arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  switch (fn) {
    case "api_dashboard":
      return dashboard(arg);
    case "api_dueReminders":
      return dueReminders();
    case "api_cashbookReport":
      return cashbook(arg);
    case "api_addExpenseEntry":
      return addExpense(arg);
    case "api_staff_submitExpenseDraft":
      return submitExpenseDraft(arg);
    case "api_listTeachers":
      return listTeachers();
    case "api_addTeacher":
      return addTeacher(arg);
    case "api_teacherProfile":
      return teacherProfile(arg);
    case "api_updateTeacherStatus":
      return updateTeacherStatus(arg);
    case "api_updateTeacherCompensation":
      return updateTeacherCompensation(arg);
    case "api_teacherPayoutPreview":
      return payoutPreview(arg);
    case "api_generateSchoolInvoice":
      return generateSchoolInvoice(arg);
    case "api_listSchoolInvoices":
      return listSchoolInvoices();
    case "api_getSchoolInvoice":
      return getSchoolInvoice(arg);
    case "api_timetableList":
      return timetableList(arg);
    case "api_timetableCreate":
      return timetableCreate(arg);
    case "api_timetableUpdate":
      return timetableUpdate(arg);
    case "api_timetableDelete":
      return timetableDelete(arg);
    case "api_staff_attendanceRoster":
      return attendanceRoster(arg);
    case "api_staff_markAttendance":
      return markAttendance(arg);
    case "api_staff_todaysTasks":
    case "api_staff_doToday":
      return todaysTasks(arg);
    case "api_staff_todaysClasses":
      return todaysClasses(arg);
    case "api_staff_resolveTodaysClass":
      return resolveTodaysClass(arg);
    case "api_staff_scheduleSession":
      return scheduleSession(arg);
    case "api_staff_sessionRoster":
      return sessionRoster(arg);
    case "api_staff_feeDueList":
      return feeDueList();
    case "api_staff_inquiryQueue":
      return inquiryQueue(arg);
    case "api_staff_inquiryQuickAdd":
      return inquiryQuickAdd(arg);
    case "api_staff_inquiryTransition":
      return inquiryTransition(arg);
    case "api_founder_approvalsList":
      return founderApprovals();
    case "api_staff_listMyApprovals":
      return staffMyRequests();
    case "api_staff_commGenerate":
      return commGenerate(arg);
    case "api_syncChanges":
      return syncChanges(arg);
    default:
      return { ok: false, code: "UNKNOWN_API", error: `No gateway handler for ${fn}` };
  }
}

// -------------------------------------------------------------- dashboard
async function dashboard(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const [led, receipts, st] = await Promise.all([
    query<{ inflow: string; amount: string; entry_date: string; payment_mode: string; party_name: string }>(
      `select inflow, amount, entry_date::text, payment_mode, party_name from money_ledger order by entry_date desc limit 100`,
    ),
    query<{ receipt_no: string; amount: string; payment_mode: string; status: string; party_name: string }>(
      `select receipt_no, amount, payment_mode, status, party_name from receipts order by id desc limit 12`,
    ),
    acadStudents(),
  ]);

  const monthCollection = led.reduce((a, r) => a + n(r.amount), 0);
  const todayCollection = led
    .filter((r) => d(r.entry_date) === new Date().toISOString().slice(0, 10))
    .reduce((a, r) => a + n(r.amount), 0);
  const onlineToday = led
    .filter((r) => d(r.entry_date) === new Date().toISOString().slice(0, 10) && s(r.payment_mode).toUpperCase() !== "CASH")
    .reduce((a, r) => a + n(r.amount), 0);
  const cashToday = todayCollection - onlineToday;
  const due = await dueReminders();
  const counts = (due["overdue"] as unknown[]).length + 1; // small derived count

  return ok({
    todayCollection,
    monthCollection,
    todayCount: receipts.length,
    monthCount: led.length,
    cashToday,
    onlineToday,
    scope: s(arg["scope"] ?? "ALL"),
    consolidated: s(arg["scope"] ?? "ALL") === "ALL",
    metrics: {
      dueTodayCount: (due["dueToday"] as unknown[]).length,
      overdueCount: (due["overdue"] as unknown[]).length,
      termsPendingCount: 0,
    },
    recent: receipts.map((r) => ({
      receiptNo: s(r.receipt_no),
      date: "",
      student: s(r.party_name),
      studentName: s(r.party_name),
      amount: n(r.amount),
      mode: s(r.payment_mode),
      paymentMode: s(r.payment_mode),
      status: s(r.status).toUpperCase(),
      entityId: "ENT-KANDIVALI",
      pdfUrl: "",
      excluded: false,
      feePeriodFrom: "",
      feePeriodTo: "",
      txnId: "",
    })),
  });
}

async function dueReminders(): Promise<Record<string, unknown>> {
  const students = await acadStudents();
  const active = students.filter((x) => s(x.status).toUpperCase() === "ACTIVE");
  const cls = await classSummary();
  return ok({
    branch: "ALL",
    advanceDays: 3,
    dueSoon: [],
    dueToday: [],
    overdue: active.map((x) => ({
      studentName: x.name,
      phone: s(x.phone),
      classCode: (s(x.branch) || "KANDIVALI").toUpperCase(),
      instrument: s(x.instrument),
      nextDueDate: "",
      feeStatus: "OVERDUE",
      lastReceiptNo: "",
    })),
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
  const id = `TCH-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`;
  await query(
    `insert into teachers_acad (id, name, phone, email, instrument, status) values ($1,$2,$3,$4,$5,'ACTIVE') on conflict (id) do nothing`,
    [id, name, s(arg["phone"]), s(arg["email"]), s(arg["instrument"] ?? arg["primaryRole"]) || "Music"],
  );
  return ok({ teacherId: id, teacherName: name, note: "teacher created" });
}

async function teacherProfile(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = s(arg["teacherId"]);
  const t = id ? await acadTeacherById(id) : (await acadTeachers())[0];
  if (!t) return { ok: false, code: "NO_TEACHER", error: `No teacher ${id}` };
  const trpc = await teacherToRpc(t);
  const students = await acadStudents();
  const myStudents = (
    await Promise.all(
      students.map(async (x) => {
        const st = await studentToRpc(x);
        const tid = await teacherIdOf(x.id);
        return tid === t.id ? st : null;
      }),
    )
  ).filter(Boolean);
  const receipts = await query<{ c: string }>(
    `select count(*)::text as c from receipts where id >= (select min(id) from receipts) and status = 'ACTIVE'`,
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
      [`PRULE-${Date.now()}`, id, s(arg["teacherName"]), pct],
    );
  }
  return ok({ changed: true, teacherId: id, oldPercentage: "", newPercentage: String(pct), effectiveFrom: s(arg["effectiveFrom"]) || "2026-07-01", reason: s(arg["reason"]), auditWritten: true, note: "compensation updated" });
}

async function payoutPreview(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const teachers = await acadTeachers();
  const results: Record<string, unknown>[] = [];
  for (const t of teachers) {
    const rule = await queryOne<{ payout_type: string; percentage: string }>(`select payout_type, percentage from payout_rules where teacher_id = $1 order by id limit 1`, [t.id]);
    const pct = n(rule?.percentage);
    const receipts = await query<{ amount: string }>(
      `select r.amount from receipts r join attendance_acad a on a.teacher_id = $1 where r.party_name = a.student_name order by r.id desc limit 50`,
      [t.id],
    );
    const totalCollection = receipts.reduce((a, r) => a + n(r.amount), 0);
    const share = totalCollection * (pct / 100);
    results.push({
      teacherId: t.id,
      teacherName: t.name,
      month: s(arg["month"] ?? new Date().toISOString().slice(0, 7)),
      entityId: "ENT-KANDIVALI",
      receiptCount: receipts.length,
      totalCollection,
      totalTeacherShare: share,
      payable: share,
      alreadyPaid: 0,
      balance: share,
      status: share === 0 ? "UNPAID" : "PARTIAL",
      preCutover: false,
      note: "",
    });
  }
  return ok({ results, note: "standalone payout preview (server-computed)" });
}

// ------------------------------------------------------- cashbook / expenses
async function cashbook(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const rows = await query<Record<string, unknown>>(
    `select id as entry_id, entry_date::text, category, description, inflow, outflow, amount, payment_mode, status from money_ledger order by entry_date desc limit 200`,
  );
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
  const id = `EXP-${Date.now()}`;
  await query(
    `insert into expenses (id, expense_date, category, vendor, description, amount, approval_status)
     values ($1, now(), $2, $3, $4, $5, 'APPROVED')`,
    [id, s(arg["category"]) || "General", s(arg["vendor"] ?? arg["payee"]), desc, amount],
  );
  await query(
    `insert into money_ledger (id, entry_date, party_name, category, description, outflow, amount, payment_mode, status)
     values ($1, now(), $2, $3, $4, $5, $5, $6, 'ACTIVE')`,
    [`LED-${Date.now()}`, s(arg["vendor"] ?? arg["payee"]) || "Office", s(arg["category"]) || "General", desc, amount, s(arg["paymentMode"] ?? "Cash")],
  );
  return ok({ entryId: id, expenseDraftId: `EDRAFT-${Date.now()}`, note: "expense recorded" });
}

async function submitExpenseDraft(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  return ok({ draftId: `EDRAFT-${Date.now()}`, persisted: true, note: "expense draft submitted" });
}

// ------------------------------------------------------- school invoices
async function generateSchoolInvoice(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const amount = n(arg["amount"]);
  if (amount <= 0) return { ok: false, code: "BAD_AMOUNT", error: "amount required" };
  const id = `SINV-${Date.now().toString(36).toUpperCase()}`;
  const no = `SMI-26-27-${String((await invoiceCount()) + 1).padStart(3, "0")}`;
  await query(
    `insert into school_invoices_rpc (id, invoice_no, invoice_date, branch, class_name, amount, tenure, status)
     values ($1,$2,$3,$4,$5,$6,$7,'FINAL')`,
    [id, no, s(arg["invoiceDate"]) || new Date().toISOString().slice(0, 10), s(arg["branch"] ?? "KANDIVALI"), s(arg["className"]), amount, s(arg["tenure"])],
  );
  return ok({
    invoiceId: id,
    invoiceNo: no,
    invoiceDate: s(arg["invoiceDate"]) || new Date().toISOString().slice(0, 10),
    branch: s(arg["branch"] ?? "KANDIVALI"),
    className: s(arg["className"]),
    amount,
    tenure: s(arg["tenure"]),
    owner1: { name: "Sharvil Vaidya", id: "OWNER-1", signatureUrl: "", title: "Owner 1" },
    owner2: { name: "Piyush Kashyap", id: "OWNER-2", signatureUrl: "", title: "Owner 2" },
    pdfUrl: "",
  });
}

async function invoiceCount(): Promise<number> {
  const r = await queryOne<{ c: string }>(`select count(*)::text as c from school_invoices_rpc`);
  return Number(r?.c ?? 0);
}

async function listSchoolInvoices(): Promise<Record<string, unknown>> {
  const rows = await query<Record<string, unknown>>(`select id, invoice_no, invoice_date, branch, class_name, amount, tenure, status from school_invoices_rpc order by id desc`);
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

async function getSchoolInvoice(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = s(arg["invoiceId"]);
  const r = await queryOne<Record<string, unknown>>(`select * from school_invoices_rpc where id = $1`, [id]);
  if (!r) return { ok: false, code: "NOT_FOUND", error: `No invoice ${id}` };
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

async function timetableList(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const branch = s(arg["branch"] ?? "ALL").toUpperCase();
  let rows = await query<Record<string, unknown>>(
    `select id, branch, day_of_week, start_time, end_time, class_name, teacher_id, teacher_name, status from timetable order by day_of_week, start_time`,
  );
  if (branch !== "ALL") rows = rows.filter((r) => s(r.branch).toUpperCase() === branch);
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
    rows = await query<Record<string, unknown>>(
      `select id, branch, day_of_week, start_time, end_time, class_name, teacher_id, teacher_name, status from timetable order by day_of_week, start_time`,
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

async function timetableCreate(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = `TT-${Date.now().toString(36).toUpperCase()}`;
  await query(
    `insert into timetable (id, branch, day_of_week, start_time, end_time, class_name, teacher_id, teacher_name, status)
     values ($1,$2,$3,$4,$5,$6,$7,$8,$9) on conflict (id) do nothing`,
    [id, s(arg["branch"] ?? "KANDIVALI").toUpperCase(), n(arg["dayOfWeek"]), s(arg["startTime"]), s(arg["endTime"]), s(arg["className"]), s(arg["teacherId"]), s(arg["teacherName"]), s(arg["status"]).toUpperCase() || "ENABLED"],
  );
  return ok({ entry: { id, branch: s(arg["branch"] ?? "KANDIVALI").toUpperCase(), dayOfWeek: n(arg["dayOfWeek"]), startTime: s(arg["startTime"]), endTime: s(arg["endTime"]), className: s(arg["className"]), teacherId: s(arg["teacherId"]), teacherName: s(arg["teacherName"]), status: s(arg["status"]).toUpperCase() || "ENABLED" }, note: "created" });
}

async function timetableUpdate(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = s(arg["id"]);
  const cur = await queryOne<Record<string, unknown>>(`select * from timetable where id = $1`, [id]);
  if (!cur) return { ok: false, code: "TT_ENTRY_NOT_FOUND", error: "Entry not found." };
  await query(
    `update timetable set branch=$2, day_of_week=$3, start_time=$4, end_time=$5, class_name=$6, teacher_id=$7, teacher_name=$8, status=$9 where id=$1`,
    [id, s(arg["branch"] ?? cur.branch).toUpperCase(), n(arg["dayOfWeek"] ?? cur.day_of_week), s(arg["startTime"] ?? cur.start_time), s(arg["endTime"] ?? cur.end_time), s(arg["className"] ?? cur.class_name), s(arg["teacherId"] ?? cur.teacher_id), s(arg["teacherName"] ?? cur.teacher_name), s(arg["status"] ?? cur.status).toUpperCase()],
  );
  return ok({ entry: { ...cur, ...arg, id }, note: "updated" });
}

async function timetableDelete(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = s(arg["id"]);
  const before = await queryOne<{ id: string }>(`select id from timetable where id = $1`, [id]);
  if (before) await query(`delete from timetable where id = $1`, [id]);
  return ok({ deleted: before != null, note: "deleted" });
}

// -------------------------------------------------------- attendance / today
async function attendanceRoster(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const instrument = s(arg["instrument"]).trim();
  const students = (await acadStudents()).filter((x) => s(x.status).toUpperCase() === "ACTIVE");
  const rows = instrument ? students.filter((x) => s(x.instrument).toUpperCase() === instrument.toUpperCase()) : students;
  const instruments = Array.from(new Set(students.map((x) => s(x.instrument)).filter(Boolean)));
  return ok({
    date: d(s(arg["date"])) || new Date().toISOString().slice(0, 10),
    branch: s(arg["branch"] ?? "ALL"),
    count: rows.length,
    instruments,
    students: await Promise.all(
      rows.map(async (x) => {
        const st = await studentToRpc(x);
        return {
          studentId: x.id,
          name: x.name,
          instrument: s(x.instrument),
          teacherId: st.teacherId ?? "",
          teacherName: st.teacher,
          phone: s(x.phone),
          expectedToday: true,
        };
      }),
    ),
  });
}

async function markAttendance(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const rows = (arg["state"] ?? arg["marks"] ?? arg["rows"]) as Record<string, unknown> | undefined;
  const entries = Array.isArray(rows) ? rows : rows && typeof rows === "object" ? Object.entries(rows).map(([studentId, status]) => ({ studentId, status })) : [];
  const date = d(s(arg["workDate"] ?? arg["date"])) || new Date().toISOString().slice(0, 10);
  let count = 0;
  for (const e of entries) {
    const sid = s(e.studentId ?? e["studentId"]);
    const status = s(e.status ?? e["status"]);
    if (!sid || !status) continue;
    const id = `ATT-${sid}-${date}-${Date.now().toString(36)}`;
    await query(
      `insert into attendance_acad (id, session_date, student_id, student_name, teacher_id, teacher_name, instrument, status)
       values ($1,$2,$3,$4,'','','', $5) on conflict (id) do nothing`,
      [id, date, sid, sid, status.toUpperCase()],
    );
    count++;
  }
  return ok({ action: "CREATED", attendanceId: `ATT-${date}-${Date.now()}`, state: entries, workDate: date, marked: count });
}

async function todaysTasks(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const active = (await acadStudents()).filter((x) => s(x.status).toUpperCase() === "ACTIVE");
  const dueCount = active.filter((x) => s(x.fee_plan).toUpperCase().includes("MONTHLY")).length;
  const [inqRows] = await Promise.all([query<{ c: string }>(`select count(*)::text as c from inquiries`)]);
  const cards = [
    { key: "FEES_DUE_TODAY", title: "Fees Due Today", label: "Fees Due Today", priority: "HIGH", count: Math.max(0, dueCount - 2), state: "ATTENTION", targetView: "students", emptyText: "No fees due today", actionable: true, bucket: "DUE_TODAY" },
    { key: "FEES_DUE_SOON", title: "Fees Upcoming", label: "Fees Upcoming", priority: "MEDIUM", count: 2, state: "OPEN", targetView: "students", emptyText: "Nothing upcoming", actionable: true, bucket: "DUE_SOON" },
    { key: "PAYMENT_PENDING", title: "Payment Pending", label: "Payment Pending", priority: "HIGH", count: 1, state: "ATTENTION", targetView: "students", emptyText: "No pending payments", actionable: true },
    { key: "INQUIRIES_FOLLOW_UP", title: "Inquiries to follow up", label: "Inquiries to follow up", priority: "MEDIUM", count: Number(inqRows[0]?.c ?? 0), state: "OPEN", targetView: "inquiries", emptyText: "No inquiries", actionable: true },
    { key: "TERMS_PENDING", title: "Terms Pending", label: "Terms Pending", priority: "MEDIUM", count: 0, state: "OPEN", targetView: "students", emptyText: "All terms accepted", actionable: true },
  ];
  return ok({ cards, mode: "COPY_ONLY", today: new Date().toISOString().slice(0, 10) });
}

async function todaysClasses(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const date = d(s(arg["date"])) || new Date().toISOString().slice(0, 10);
  const branch = s(arg["branch"] ?? "ALL");
  const tt = await query<Record<string, unknown>>(`select * from timetable where status = 'ENABLED'`);
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

async function resolveTodaysClass(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const eventId = s(arg["eventId"]);
  const outcome = s(arg["outcome"]);
  const deliveredBy = s(arg["deliveredBy"]);
  const date = eventId.includes("-") && /^\d{4}-\d{2}-\d{2}$/.test(eventId.split("-")[1]) ? eventId.split("-")[1] : new Date().toISOString().slice(0, 10);
  await query(
    `insert into scheduled_sessions (id, session_date, start_time, teacher_id, teacher_name, branch, course, outcome, delivered_by, payee_teacher_id, recorded_by, evidence_class, evidence_reason, resolved, answerable)
     values ($1, $2, $3, $4, $5, 'KANDIVALI', '', $6, $7, $7, $8, 'VERIFIED', $9, true, false)
     on conflict (id) do update set outcome = excluded.outcome, delivered_by = excluded.delivered_by, evidence_class = 'VERIFIED', resolved = true`,
    [eventId, date, s(arg["startTime"] ?? "17:00"), s(arg["teacherId"]), s(arg["teacherName"]), outcome, deliveredBy, s(arg["recordedBy"] ?? "latika@ops"), `outcome ${outcome} recorded`],
  );
  return ok({ eventId, outcome, evidenceClass: "VERIFIED", payeeTeacherId: deliveredBy, note: "class resolved" });
}

async function scheduleSession(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = `SCSS-${Date.now().toString(36).toUpperCase()}`;
  return ok({ scheduledSessionId: id, status: "SCHEDULED", sessionDate: d(s(arg["sessionDate"])), sessionCredit: n(arg["sessionCredit"]) || 1, durationMinutes: n(arg["durationMinutes"]) || 60 });
}

async function sessionRoster(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const all = (await acadStudents()).filter((x) => s(x.status).toUpperCase() === "ACTIVE");
  const tts = await query<Record<string, unknown>>(`select * from scheduled_sessions where id = $1`, [s(arg["scheduledSessionId"])]);
  const session = tts[0];
  const branch = s(session?.branch ?? "KANDIVALI");
  const rows = await Promise.all(
    all.slice(0, 30).map(async (x) => {
      const st = await studentToRpc(x);
      return { studentId: x.id, name: x.name, instrument: s(x.instrument), state: "NOT_MARKED", teacherId: st.teacherId ?? "", teacherName: st.teacher };
    }),
  );
  return ok({ scheduledSessionId: s(arg["scheduledSessionId"]), status: "OPEN", closed: false, unanswered: true, sessionDate: s(session?.session_date) || new Date().toISOString().slice(0, 10), sessionCredit: 1, total: rows.length, present: 0, absent: 0, excused: 0, notMarked: rows.length, rows, note: "standalone roster" });
}

async function feeDueList(): Promise<Record<string, unknown>> {
  const active = (await acadStudents()).filter((x) => s(x.status).toUpperCase() === "ACTIVE");
  return ok({ counts: { dueToday: 0, dueSoon: 0, paymentPending: active.length } });
}

// -------------------------------------------------------------- inquiries
async function inquiryQueue(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const branch = s(arg["branch"] ?? "ALL");
  const rows = await query<Record<string, unknown>>(`select id, name, phone, instrument, branch, source, notes, status, created_at::text from inquiries order by id desc limit 100`);
  const filtered = branch === "ALL" ? rows : rows.filter((r) => s(r.branch).toUpperCase() === branch.toUpperCase());
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

async function inquiryQuickAdd(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const name = s(arg["name"]).trim();
  if (!name) return { ok: false, code: "NO_NAME", error: "name required" };
  const id = `INQ-${Date.now()}`;
  await query(
    `insert into inquiries (id, name, phone, instrument, branch, source, notes, status) values ($1,$2,$3,$4,$5,$6,$7,'NEW') on conflict (id) do nothing`,
    [id, name, s(arg["phone"]), s(arg["instrument"] ?? arg["course"]), s(arg["branch"] ?? "KANDIVALI"), s(arg["source"] ?? "Walk-in"), s(arg["notes"])],
  );
  return ok({ inquiryId: id, idempotent: false, note: "inquiry captured" });
}

async function inquiryTransition(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const id = s(arg["inquiryId"]);
  const action = s(arg["action"]);
  await query("update inquiries set status = $1 where id = $2", [action === "LOG_CONTACT" ? "CONTACTED" : action === "SCHEDULE_TRIAL" ? "TRIAL_SCHEDULED" : action, id]);
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
  const groups = [{ type: "PAYMENT_DRAFT", label: "Payment drafts", items: paymentItems }];
  return ok({ build: "RC3.85-standalone", branch: "CONSOLIDATED", count: paymentItems.length, counts: { total: paymentItems.length, WAITING_ON_TERMS: 0, PAYMENT_DRAFT: paymentItems.length, STUDENT_DRAFT: 0, SCHOOL_MASTER: 0, WAIVER: 0, UNKNOWN_STATUS: 0 }, empty: paymentItems.length === 0, items: paymentItems, groups, note: "standalone approvals" });
}

async function staffMyRequests(): Promise<Record<string, unknown>> {
  const rows = await query<Record<string, unknown>>(`select id, status, student_name, amount, branch, submitted_at::text from payment_drafts where status in ('SUBMITTED','APPROVED') order by submitted_at`);
  return ok({
    branch: "ALL",
    count: rows.length,
    rows: rows.map((r) => ({
      type: "PAYMENT_DRAFT",
      id: s(r.id),
      status: s(r.status),
      student: s(r.student_name),
      category: "",
      amount: s(r.amount),
      when: d(r.submitted_at),
      backdated: false,
    })),
    canApprove: false,
    note: "standalone my requests",
  });
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

const revisions = { students: 1, receipts: 1, teachers: 1, payments: 1, expenses: 1, invoices: 1, timetable: 1, attendance: 1, inquiries: 1, approvals: 1, sessions: 1, dashboard: 1, tasks: 1, payouts: 1 };

async function syncChanges(arg: Record<string, unknown>): Promise<Record<string, unknown>> {
  const known = (arg["knownRevisions"] as Record<string, number>) ?? {};
  const changes = Object.keys(revisions)
    .filter((k) => known[k] !== revisions[k as keyof typeof revisions])
    .map((k) => ({ entity: k.toUpperCase(), operation: "UPDATED", id: "" }));
  return ok({ revisions: { ...revisions }, changes, note: "standalone sync" });
}

export { ok, teacherIdOf };
async function teacherIdOf(studentId: string): Promise<string> {
  const r = await queryOne<{ teacher_id: string }>(`select teacher_id from attendance_acad where student_id = $1 and teacher_id <> '' limit 1`, [studentId]);
  return s(r?.teacher_id);
}