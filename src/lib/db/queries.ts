import { query, isDbConfigured } from "@/lib/db";
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
}

export async function loadDataset(): Promise<AcademyDataset> {
  if (!isDbConfigured) return { ...demo, progress: demo.progress, skillCategories: demo.skillCategories };

  const [instruments, teachers, students, classes, classStudents, attendance, practice, assignments, resources, progressRows, progressCategories, messages, messageParticipants, threadsRaw, notifications, announcements, invoices, payments, achievements, feedback] =
    await Promise.all([
      query<Instrument>('select id, name, icon, color from instruments order by name'),
      query<Teacher>(`select id, full_name, email, avatar_url, phone, instrument, rating from teachers`),
      query<Student>(`select id, full_name, email, avatar_url, phone, instrument, level, fee_status, parent_id from students order by full_name`),
      query<ClassEvent>(`select id, title, instrument, teacher_id, teacher_name, course_id, room, mode, status, recurring,
        start_time, end_time, duration_min, color from classes order by start_time`),
      query<{ class_id: string; student_id: string }>(`select class_id, student_id from class_students`),
      query<AttendanceRecord>(`select id, class_id, student_id, status, date from attendance`),
      query<PracticeSession>(`select id, student_id, instrument, activity, minutes, date, notes, goal_met from practice_sessions order by date desc`),
      query<Assignment>(`select id, title, description, instrument, difficulty, due_date, expected_minutes, teacher_id, teacher_name, student_id, status from assignments`),
      query<Resource>(`select id, title, instrument, level, type, duration_min, author, favorite, audio_url from learning_resources`),
      query<{ student_id: string; category: string; score: number }>(`select student_id, category, score from progress order by category`),
      query<{ id: string; name: string }>(`select id, name from progress_categories order by name`),
      query<Message>(`select id, thread_id, sender_id, sender_name, body, attachment_url, created_at from messages order by created_at`),
      query<{ thread_id: string; participant_name: string; participant_id: string }>(`select thread_id, participant_name, participant_id from message_participants`),
      query<{ id: string; updated_at: string }>(`select id, updated_at from message_threads order by updated_at desc`),
      query<NotificationItem>(`select id, user_id, title, body, type, read, created_at from notifications order by created_at desc`),
      query<Announcement>(`select id, title, body, author, audience, pinned, created_at from announcements order by created_at desc`),
      query<Invoice>(`select id, student_id, student_name, description, amount, status, issued_date, due_date from invoices order by due_date`),
      query<{ id: string; invoice_id: string; student_name: string; amount: number; method: string; status: string; paid_at: string }>(`select id, invoice_id, student_name, amount, method, status, paid_at from payments order by paid_at desc`),
      query<Achievement>(`select id, student_id, title, description, icon, earned_at from achievements`),
      query<Feedback>(`select id, student_id, teacher_id, teacher_name, body, category, created_at from teacher_feedback order by created_at desc`),
    ]);

  const rosterByClass = new Map<string, string[]>();
  for (const cs of classStudents) {
    const list = rosterByClass.get(cs.class_id) ?? [];
    list.push(cs.student_id);
    rosterByClass.set(cs.class_id, list);
  }
  const classesOut: ClassEvent[] = classes.map((c) => ({
    ...c,
    student_ids: rosterByClass.get(c.id) ?? [],
    start_time: String(c.start_time),
    end_time: String(c.end_time),
  }));

  const participantNames = new Map<string, string[]>();
  const participantIds = new Map<string, string[]>();
  for (const mp of messageParticipants) {
    const n = participantNames.get(mp.thread_id) ?? [];
    n.push(mp.participant_name);
    participantNames.set(mp.thread_id, n);
    const i = participantIds.get(mp.thread_id) ?? [];
    i.push(mp.participant_id);
    participantIds.set(mp.thread_id, i);
  }

  const lastByThread = new Map<string, Message>();
  for (const m of messages) lastByThread.set(m.thread_id, m);

  const unread: Record<string, number> = {};
  for (const mp of messageParticipants) {
    if (mp.participant_id === "s1") unread[mp.thread_id] = (unread[mp.thread_id] ?? 0) + 1;
  }

  const threads: Thread[] = threadsRaw.map((t) => {
    const last = lastByThread.get(t.id);
    return {
      id: t.id,
      participant_ids: participantIds.get(t.id) ?? [],
      participant_names: participantNames.get(t.id) ?? [],
      last_message: last?.body ?? null,
      last_message_at: last?.created_at ?? null,
      unread: unread[t.id] ?? 0,
      updated_at: String(t.updated_at),
    };
  });

  const skillCategories =
    progressCategories.map((pc) => ({
      name: pc.name,
      score: progressRows.find((p) => p.category === pc.name)?.score ?? 0,
    }));
  const overall = progressRows.length ? Math.round(progressRows.reduce((a, p) => a + p.score, 0) / progressRows.length) : 0;
  const progress: Progress = {
    student_id: "s1",
    instrument: students.find((s) => s.id === "s1")?.instrument ?? "Piano",
    level: students.find((s) => s.id === "s1")?.level ?? "Grade 3",
    categories: skillCategories,
    overall,
  };

  const weeklyHours = Array.from({ length: 7 }, (_, i) => {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    start.setDate(start.getDate() - (start.getDay() === 0 ? 6 : start.getDay() - 1) + i);
    const end = new Date(start);
    end.setDate(end.getDate() + 1);
    return practice
      .filter((p) => {
        const d = new Date(p.date);
        return d >= start && d < end;
      })
      .reduce((a, p) => a + p.minutes, 0);
  });

  return {
    instruments,
    teachers,
    students,
    classes: classesOut,
    attendance: attendance.map((a) => ({ ...a, date: String(a.date) })),
    practice: practice.map((p) => ({ ...p, date: String(p.date) })),
    assignments,
    resources,
    progress,
    skillCategories,
    messages,
    threads,
    notifications: notifications.map((n) => ({ ...n, created_at: String(n.created_at) })),
    announcements: announcements.map((a) => ({ ...a, created_at: String(a.created_at) })),
    invoices: invoices.map((i) => ({ ...i, amount: Number(i.amount) })),
    payments: payments.map((p) => ({ ...p, amount: Number(p.amount), date: String(p.paid_at) })),
    achievements: achievements.map((a) => ({ ...a, earned_at: String(a.earned_at) })),
    feedback: feedback.map((f) => ({ ...f, created_at: String(f.created_at) })),
    weeklyHours,
  };
}