import { query, queryOne, isDbConfigured } from "@/lib/db";
import type {
  Achievement,
  Announcement,
  Assignment,
  AttendanceRecord,
  ClassEvent,
  Feedback,
  Instrument,
  Invoice,
  Message,
  NotificationItem,
  PracticeSession,
  Progress,
  Resource,
  Student,
  Teacher,
  Thread,
  Role,
} from "@/types";
import * as demo from "@/lib/data/demo";

export interface AcademyDataset {
  instruments: Instrument[];
  teachers: Teacher[];
  students: Student[];
  classes: ClassEvent[];
  attendance: AttendanceRecord[];
  practice: PracticeSession[];
  assignments: Assignment[];
  resources: Resource[];
  progress: Progress;
  skillCategories: { name: string; score: number }[];
  messages: Message[];
  threads: Thread[];
  notifications: NotificationItem[];
  announcements: Announcement[];
  invoices: Invoice[];
  payments: { id: string; student_name: string; amount: number; method: string; date: string; status: string }[];
  achievements: Achievement[];
  feedback: Feedback[];
  weeklyHours: number[];
  // identity resolution helpers (mirror data)
  currentStudentId?: string;
  currentTeacherId?: string;
}

interface AcadStudentRow {
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
  enrollment_date: string;
  notes: string;
}

interface AcadTeacherRow {
  id: string;
  name: string;
  phone: string;
  email: string;
  instrument: string;
  status: string;
}

interface AcadAttendanceRow {
  id: string;
  session_date: string;
  student_id: string;
  student_name: string;
  teacher_id: string;
  teacher_name: string;
  instrument: string;
  status: string;
}

interface AcadReceiptRow {
  id: string;
  receipt_no: string;
  party_name: string;
  amount: string;
  status: string;
  payment_mode: string;
  linked_url: string;
  record_id: string;
}

interface AcadLedgerRow {
  id: string;
  entry_date: string;
  party_name: string;
  category: string;
  description: string;
  inflow: string;
  outflow: string;
  amount: string;
  payment_mode: string;
  account: string;
  status: string;
}

const toStatus = (s: string): "paid" | "pending" | "overdue" => {
  const v = String(s ?? "").toUpperCase();
  if (v.includes("PAID") || v.includes("ACTIVE")) return "paid";
  if (v.includes("OVERDUE")) return "overdue";
  return "pending";
};

export async function loadDataset(): Promise<AcademyDataset> {
  if (!isDbConfigured) return buildDemo();

  // Mirror data present? If yes, real data wins for students/teachers/attendance/invoices/payments/classes.
  const mirrorStudentCount = await queryOne<{ n: string }>(
    "select count(*)::text as n from students_acad",
  ).catch(() => null);
  const hasMirror = mirrorStudentCount !== null && Number(mirrorStudentCount.n) > 0;

  if (!hasMirror) return buildDemo();

  return loadMirror();
}

function buildDemo(): AcademyDataset {
  return {
    instruments: demo.instruments,
    teachers: demo.teachers,
    students: demo.students,
    classes: demo.classes,
    attendance: demo.attendance,
    practice: demo.practice,
    assignments: demo.assignments,
    resources: demo.resources,
    progress: demo.progress,
    skillCategories: demo.skillCategories,
    messages: demo.messages,
    threads: demo.threads,
    notifications: demo.notifications,
    announcements: demo.announcements,
    invoices: demo.invoices,
    payments: demo.payments,
    achievements: demo.achievements,
    feedback: demo.feedback,
    weeklyHours: demo.weeklyHours,
  };
}

async function loadMirror(): Promise<AcademyDataset> {
  const [acadStudents, acadTeachers, acadAttendance, acadReceipts, acadLedger, acadInquiries] = await Promise.all([
    query<AcadStudentRow>(`select id, name, guardian_name, phone, email, instrument, branch, batch, fee_plan, status, enrollment_date::text, notes from students_acad`),
    query<AcadTeacherRow>(`select id, name, phone, email, instrument, status from teachers_acad`),
    query<AcadAttendanceRow>(`select id, session_date::text, student_id, student_name, teacher_id, teacher_name, instrument, status from attendance_acad`),
    query<AcadReceiptRow>(`select id, receipt_no, party_name, amount, status, payment_mode, linked_url, record_id from receipts`),
    query<AcadLedgerRow>(`select id, entry_date::text, party_name, category, description, inflow, outflow, amount, payment_mode, account, status from money_ledger`),
    query<{ id: string; name: string; notes: string }>(`select id, name, notes from inquiries`),
  ]);

  const teachers: Teacher[] = acadTeachers.map((t) => ({
    id: t.id,
    full_name: t.name,
    email: t.email || `${t.id.toLowerCase()}@swarmangal.in`,
    role: "teacher" as Role,
    avatar_url: null,
    instrument: t.instrument || "Music",
    rating: 4.8,
  }));

  const students: Student[] = acadStudents.map((s) => ({
    id: s.id,
    full_name: s.name,
    email: s.email || `${s.id.toLowerCase()}@swarmangal.in`,
    role: "student" as Role,
    avatar_url: null,
    instrument: s.instrument || "Music",
    level: s.fee_plan || "Beginner",
    fee_status: toStatus(s.status),
  }));

  // Classes derived from real attendance: group by (session_date, teacher, instrument).
  const classGroups = new Map<string, { meta: ClassEvent; roster: Set<string> }>();
  for (const a of acadAttendance) {
    const key = `${a.session_date}|${a.teacher_id}|${a.instrument}`;
    let g = classGroups.get(key);
    if (!g) {
      g = {
        meta: {
          id: `CLS-${a.session_date}-${a.teacher_id}-${a.instrument.replace(/\s+/g, "")}`,
          title: `${a.instrument || "Music"} Class`,
          instrument: a.instrument || "Music",
          teacher_id: a.teacher_id || "",
          teacher_name: a.teacher_name || "Teacher",
          course_id: null,
          student_ids: [],
          start_time: `${a.session_date}T17:30:00`,
          end_time: `${a.session_date}T18:30:00`,
          duration_min: 60,
          room: null,
          mode: "offline" as const,
          status: "completed" as const,
          recurring: null,
          color: "#8d6bf6",
        },
        roster: new Set(),
      };
      classGroups.set(key, g);
    }
    g.roster.add(a.student_id);
  }
  const classes: ClassEvent[] = Array.from(classGroups.values()).map((g) => ({
    ...g.meta,
    student_ids: Array.from(g.roster).filter(Boolean),
  }));

  const attendance: AttendanceRecord[] = acadAttendance.map((a) => ({
    id: a.id,
    class_id: `CLS-${a.session_date}-${a.teacher_id}-${(a.instrument || "").replace(/\s+/g, "")}`,
    student_id: a.student_id,
    status: (a.status || "present").toLowerCase() as AttendanceRecord["status"],
    date: a.session_date,
  }));

  // Invoices <- real receipts
  const invoices: Invoice[] = acadReceipts.map((r) => {
    const student = students.find((s) => r.party_name && s.full_name.toLowerCase() === r.party_name.toLowerCase());
    return {
      id: r.receipt_no || r.id,
      student_id: student?.id ?? notFoundId(r.party_name),
      student_name: r.party_name || `Student (${r.receipt_no || r.id})`,
      amount: Number(r.amount) || 0,
      status: toStatus(r.status),
      due_date: "",
      issued_date: "",
      description: `Receipt ${r.receipt_no}`,
    };
  });

  // Payments <- real money ledger (inflow lines)
  const payments = acadLedger
    .filter((l) => Number(l.inflow) > 0)
    .map((l) => ({
      id: l.id,
      student_name: l.party_name || "Payment",
      amount: Number(l.inflow) || 0,
      method: l.payment_mode || "Cash",
      date: l.entry_date || "",
      status: "paid",
    }));

  // Notifications <- student-relevant real signals (inquiries w/ notes -> announcements feed; keep minimal)
  const notifications: NotificationItem[] = acadInquiries.slice(0, 8).map((i, idx) => ({
    id: `N-${i.id}`,
    title: `New inquiry — ${i.name}`,
    body: String(i.notes || "").slice(0, 120) || "Follow up on this lead.",
    created_at: "",
    read: idx < 3,
    type: "inquiry",
  }));

  // announcements from real data if available, else demo
  const announcements = demo.announcements.slice(0, 2);

  const studentFor = (id: string) => students.find((s) => s.id === id);
  const progress: Progress = {
    student_id: students[0]?.id ?? "s1",
    instrument: studentFor(students[0]?.id ?? "")?.instrument ?? "Music",
    level: studentFor(students[0]?.id ?? "")?.level ?? "Beginner",
    categories: demo.skillCategories,
    overall: 67,
  };

  // Attendance-derived weekly hours (real)
  const weeklyHours = Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    const start = new Date(d);
    start.setHours(0, 0, 0, 0);
    start.setDate(d.getDate() - ((d.getDay() + 6) % 7) + i);
    return attendance.filter((a) => a.date >= start.toISOString().slice(0, 10) && a.date < new Date(start.getTime() + 86400000).toISOString().slice(0, 10)).length;
  });

  const currentStudentId = students[0]?.id ?? "s1";
  const currentTeacherId = teachers[0]?.id ?? "t1";

  return {
    instruments: demo.instruments,
    teachers,
    students,
    classes,
    attendance,
    practice: demo.practice,
    assignments: demo.assignments,
    resources: demo.resources,
    progress,
    skillCategories: demo.skillCategories,
    messages: demo.messages,
    threads: demo.threads,
    notifications,
    announcements,
    invoices,
    payments,
    achievements: demo.achievements,
    feedback: demo.feedback,
    weeklyHours,
    currentStudentId,
    currentTeacherId,
  };
}

function notFoundId(name: string): string {
  return name ? `STU-${name.replace(/\s+/g, "-").toUpperCase()}` : "";
}