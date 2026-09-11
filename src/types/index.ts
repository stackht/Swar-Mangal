export type Role = "admin" | "teacher" | "student" | "parent";

export interface Profile {
  id: string;
  email: string;
  full_name: string;
  role: Role;
  avatar_url?: string | null;
  phone?: string | null;
  created_at?: string;
}

export interface Instrument {
  id: string;
  name: string;
  icon: string;
  color: string;
}

export interface Course {
  id: string;
  name: string;
  instrument: string;
  level: string;
  description?: string | null;
  color: string;
}

export interface Teacher extends Profile {
  instrument: string;
  rating?: number;
}

export interface Student extends Profile {
  instrument: string;
  level: string;
  batch_id?: string | null;
  parent_id?: string | null;
  fee_status: "paid" | "pending" | "overdue" | "partial";
}

export interface ClassEvent {
  id: string;
  title: string;
  instrument: string;
  teacher_id: string;
  teacher_name: string;
  course_id?: string | null;
  student_ids: string[];
  start_time: string;
  end_time: string;
  duration_min: number;
  room?: string | null;
  mode: "online" | "offline";
  status: "scheduled" | "cancelled" | "completed";
  recurring?: string | null;
  color: string;
}

export type AttendanceStatus = "present" | "absent" | "late" | "excused";

export interface AttendanceRecord {
  id: string;
  class_id: string;
  student_id: string;
  status: AttendanceStatus;
  date: string;
  marked_by?: string | null;
}

export interface PracticeSession {
  id: string;
  student_id: string;
  instrument: string;
  activity: string;
  minutes: number;
  date: string;
  notes?: string | null;
  goal_met?: boolean;
}

export type AssignmentStatus = "pending" | "submitted" | "reviewed" | "overdue";

export interface Assignment {
  id: string;
  title: string;
  description?: string | null;
  instrument: string;
  difficulty: "beginner" | "intermediate" | "advanced";
  due_date: string;
  expected_minutes: number;
  teacher_id: string;
  teacher_name: string;
  student_id: string;
  status: AssignmentStatus;
  attachments?: string[];
}

export interface Resource {
  id: string;
  title: string;
  instrument: string;
  level: string;
  type: "sheet_music" | "exercise" | "scales" | "chords" | "theory" | "song" | "audio" | "video" | "lesson";
  duration_min?: number | null;
  author?: string | null;
  favorite?: boolean;
  audio_url?: string | null;
}

export interface SkillCategory {
  name: string;
  score: number;
}

export interface Progress {
  student_id: string;
  instrument: string;
  level: string;
  categories: SkillCategory[];
  overall: number;
}

export interface Message {
  id: string;
  thread_id: string;
  sender_id: string;
  sender_name: string;
  body: string;
  created_at: string;
  attachment_url?: string | null;
}

export interface Thread {
  id: string;
  participant_ids: string[];
  participant_names: string[];
  last_message?: string | null;
  last_message_at?: string | null;
  unread?: number;
  updated_at: string;
}

export interface NotificationItem {
  id: string;
  title: string;
  body: string;
  created_at: string;
  read: boolean;
  type: string;
}

export interface Announcement {
  id: string;
  title: string;
  body: string;
  author: string;
  created_at: string;
  audience: string;
  pinned?: boolean;
}

export interface Invoice {
  id: string;
  student_id: string;
  student_name: string;
  amount: number;
  status: "paid" | "pending" | "overdue";
  due_date: string;
  issued_date: string;
  description: string;
}

export interface Achievement {
  id: string;
  title: string;
  description?: string | null;
  icon: string;
  earned_at: string;
  student_id: string;
}

export interface Feedback {
  id: string;
  student_id: string;
  teacher_id: string;
  teacher_name: string;
  body: string;
  created_at: string;
  category?: string | null;
}

export interface ActivityItem {
  id: string;
  type: "lesson" | "assignment" | "practice" | "feedback" | "payment" | "class" | "teacher";
  title: string;
  detail: string;
  created_at: string;
}

export interface Conflict {
  id: string;
  type: "teacher" | "room";
  message: string;
}
