import { query, queryOne } from "@/lib/db";

const s = (v: unknown): string => (v == null ? "" : String(v));
const n = (v: unknown): number => {
  const x = Number(String(v ?? "").replace(/[^\d.\-]/g, "") || 0);
  return Number.isFinite(x) ? x : 0;
};
const d = (v: unknown): string => {
  const x = s(v);
  return x.length > 10 ? x.slice(0, 10) : x;
};

export { s, n, d };

export interface AcadStudent {
  id: string;
  name: string;
  guardian_name: string;
  phone: string;
  email: string;
  instrument: string;
  branch: string;
  batch: string;
  fee_plan: string;
  status: string;
  notes: string;
}

export interface AcadTeacher {
  id: string;
  name: string;
  phone: string;
  email: string;
  instrument: string;
  status: string;
}

export async function acadStudents(filter = ""): Promise<AcadStudent[]> {
  if (!filter) {
    return query<AcadStudent>(
      `select id, name, guardian_name, phone, email, instrument, branch, batch, fee_plan, status, notes from students_acad order by name`,
    );
  }
  return query<AcadStudent>(
    `select id, name, guardian_name, phone, email, instrument, branch, batch, fee_plan, status, notes
     from students_acad
     where id ilike $1 or name ilike $1 or phone ilike $1 or instrument ilike $1
     order by name`,
    [`%${filter}%`],
  );
}

export async function acadStudentById(id: string): Promise<AcadStudent | null> {
  return queryOne<AcadStudent>(
    `select id, name, guardian_name, phone, email, instrument, branch, batch, fee_plan, status, notes from students_acad where id = $1`,
    [id],
  );
}

export async function acadTeachers(): Promise<AcadTeacher[]> {
  return query<AcadTeacher>(`select id, name, phone, email, instrument, status from teachers_acad order by name`);
}

export async function acadTeacherById(id: string): Promise<AcadTeacher | null> {
  return queryOne<AcadTeacher>(`select id, name, phone, email, instrument, status from teachers_acad where id = $1`, [id]);
}

// --------------------------------------------------------------------------
// student RPC shape (mirrors api_searchStudent / api_staff_* row contract)
// --------------------------------------------------------------------------
export interface StudentRpc {
  studentId: string;
  studentName: string;
  phone: string;
  email: string;
  instrument: string;
  teacher: string;
  classCode: string;
  className: string;
  location: string;
  batch: string;
  feeCycleType: string;
  feeDueDay: string;
  nextDueDate: string;
  feeStatus: string;
  lastReceiptNo: string;
  lastReceiptAmount: string;
  status: string;
  teacherId?: string;
}

export async function studentToRpc(x: AcadStudent): Promise<StudentRpc> {
  let teacherName = "";
  const g = await query<{ teacher_name: string }>(
    `select distinct teacher_name from attendance_acad where student_id = $1 and teacher_name <> '' limit 1`,
    [x.id],
  );
  if (g.length) teacherName = g[0].teacher_name;
  const last = await queryOne<{ receipt_no: string; amount: string }>(
    `select receipt_no, amount from receipts where party_name = $1 order by id desc limit 1`,
    [x.name],
  );
  const status = s(x.status).toUpperCase();
  return {
    studentId: x.id,
    studentName: x.name,
    phone: s(x.phone),
    email: s(x.email),
    instrument: s(x.instrument),
    teacher: teacherName,
    classCode: (s(x.branch) || "KANDIVALI").toUpperCase(),
    className: s(x.branch) === "GOREGAON" ? "Goregaon Music Class" : "Kandivali Music Class",
    location: s(x.branch).toUpperCase(),
    batch: s(x.batch),
    feeCycleType: feeCycleFromPlan(s(x.fee_plan)),
    feeDueDay: "",
    nextDueDate: "",
    feeStatus: status.startsWith("ACTIVE") ? "PAID" : status === "LEFT" ? "INACTIVE" : status === "DUPLICATE" ? "ACTIVE" : "DUE_SOON",
    lastReceiptNo: last?.receipt_no ?? "",
    lastReceiptAmount: last ? String(n(last.amount)) : "",
    status,
  };
}

export function feeCycleFromPlan(plan: string): string {
  const p = plan.toUpperCase();
  if (p.includes("3 MONTH") || p.includes("THREE")) return "3 Months";
  if (p.includes("6 MONTH") || p.includes("SIX")) return "6 Months";
  if (p.includes("YEAR") || p.includes("12")) return "Yearly";
  return "Monthly";
}

export async function teacherToRpc(x: AcadTeacher): Promise<Record<string, unknown>> {
  const rule = await queryOne<{ payout_type: string; percentage: string }>(
    `select payout_type, percentage from payout_rules where teacher_id = $1 order by id limit 1`,
    [x.id],
  );
  const streams = rule?.payout_type === "OWNER_DIRECT" ? "SCHOOL" : rule?.payout_type === "SCHOOL_CONTRACT" ? "ACADEMY|SCHOOL" : "ACADEMY";
  return {
    teacherId: x.id,
    teacherName: x.name,
    phone: s(x.phone),
    email: s(x.email),
    primaryRole: s(x.instrument),
    payoutStreams: streams,
    payoutModel: rule?.payout_type === "PERCENTAGE" ? "SHARE" : rule?.payout_type === "OWNER_DIRECT" ? "OWNER_DIRECT" : "SHARE",
    branchClassCode: "KMC",
    status: s(x.status),
    academyShare: rule ? `${s(rule.percentage) || "50"}` : "",
  };
}

export async function classSummary(): Promise<{ gmc: number; kmc: number }> {
  const r = await query<{ branch: string; c: string }>(
    `select coalesce(nullif(branch,''),'KANDIVALI') as branch, count(*)::text as c from students_acad group by branch`,
  );
  let gmc = 0;
  let kmc = 0;
  for (const row of r) {
    if (s(row.branch).toUpperCase().includes("GOR")) gmc = Number(row.c) || 0;
    else kmc = Number(row.c) || 0;
  }
  return { gmc, kmc };
}