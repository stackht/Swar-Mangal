import type {
  Achievement,
  ActivityItem,
  Announcement,
  Assignment,
  AttendanceRecord,
  AttendanceStatus,
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

const now = Date.now();
const day = 24 * 60 * 60 * 1000;
const iso = (offsetDays: number, h: number, m = 0) =>
  new Date(new Date(now).setHours(h, m, 0, 0) + offsetDays * day).toISOString();

export const instruments: Instrument[] = [
  { id: "inst-1", name: "Piano", icon: "Piano", color: "#8d6bf6" },
  { id: "inst-2", name: "Guitar", icon: "Guitar", color: "#2dbd7f" },
  { id: "inst-3", name: "Violin", icon: "Violin", color: "#ff8f3f" },
  { id: "inst-4", name: "Drums", icon: "Drum", color: "#5b8def" },
  { id: "inst-5", name: "Keyboard", icon: "KeyboardMusic", color: "#e0608a" },
  { id: "inst-6", name: "Vocals", icon: "Mic2", color: "#8d6bf6" },
  { id: "inst-7", name: "Flute", icon: "Waves", color: "#2dbd7f" },
];

export const teachers: Teacher[] = [
  { id: "t1", email: "sarah.mitchell@maestro.app", full_name: "Sarah Mitchell", role: "teacher", instrument: "Piano", avatar_url: null, rating: 4.9 },
  { id: "t2", email: "david.chen@maestro.app", full_name: "David Chen", role: "teacher", instrument: "Guitar", avatar_url: null, rating: 4.8 },
  { id: "t3", email: "emma.davis@maestro.app", full_name: "Emma Davis", role: "teacher", instrument: "Vocals", avatar_url: null, rating: 4.7 },
  { id: "t4", email: "liam.nguyen@maestro.app", full_name: "Liam Nguyen", role: "teacher", instrument: "Violin", avatar_url: null, rating: 4.6 },
];

export const students: Student[] = [
  { id: "s1", email: "aarav.sharma@maestro.app", full_name: "Aarav Sharma", role: "student", avatar_url: null, instrument: "Piano", level: "Grade 3", fee_status: "paid" },
  { id: "s2", email: "meera.patel@maestro.app", full_name: "Meera Patel", role: "student", avatar_url: null, instrument: "Guitar", level: "Beginner", fee_status: "pending" },
  { id: "s3", email: "kai.tanaka@maestro.app", full_name: "Kai Tanaka", role: "student", avatar_url: null, instrument: "Piano", level: "Grade 4", fee_status: "paid" },
  { id: "s4", email: "zara.khan@maestro.app", full_name: "Zara Khan", role: "student", avatar_url: null, instrument: "Vocals", level: "Intermediate", fee_status: "overdue" },
  { id: "s5", email: "leo.rossi@maestro.app", full_name: "Leo Rossi", role: "student", avatar_url: null, instrument: "Drums", level: "Grade 2", fee_status: "paid" },
  { id: "s6", email: "isha.reddy@maestro.app", full_name: "Isha Reddy", role: "student", avatar_url: null, instrument: "Violin", level: "Grade 3", fee_status: "pending" },
  { id: "s7", email: "noah.wilson@maestro.app", full_name: "Noah Wilson", role: "student", avatar_url: null, instrument: "Guitar", level: "Intermediate", fee_status: "paid" },
  { id: "s8", email: "aisha.ali@maestro.app", full_name: "Aisha Ali", role: "student", avatar_url: null, instrument: "Flute", level: "Beginner", fee_status: "paid" },
  { id: "s9", email: "ethan.moore@maestro.app", full_name: "Ethan Moore", role: "student", avatar_url: null, instrument: "Keyboard", level: "Grade 2", fee_status: "partial" },
  { id: "s10", email: "priya.nair@maestro.app", full_name: "Priya Nair", role: "student", avatar_url: null, instrument: "Piano", level: "Grade 5", fee_status: "paid" },
];

const t = (id: string) => teachers.find((x) => x.id === id)!;
const S = (id: string) => students.find((x) => x.id === id)!;

export const classes: ClassEvent[] = [
  {
    id: "c1", title: "Piano Fundamentals", instrument: "Piano", teacher_id: "t1", teacher_name: t("t1").full_name,
    course_id: "co1", student_ids: ["s1", "s3"], start_time: iso(0, 17, 30), end_time: iso(0, 18, 15),
    duration_min: 45, room: "Studio A", mode: "offline", status: "scheduled", recurring: "weekly", color: "#8d6bf6",
  },
  {
    id: "c2", title: "Piano Advanced", instrument: "Piano", teacher_id: "t1", teacher_name: t("t1").full_name,
    course_id: "co2", student_ids: ["s10"], start_time: iso(0, 10, 0), end_time: iso(0, 10, 45),
    duration_min: 45, room: "Studio A", mode: "offline", status: "scheduled", recurring: "weekly", color: "#8d6bf6",
  },
  {
    id: "c3", title: "Guitar Beginner", instrument: "Guitar", teacher_id: "t2", teacher_name: t("t2").full_name,
    course_id: null, student_ids: ["s2", "s8"], start_time: iso(0, 11, 0), end_time: iso(0, 11, 45),
    duration_min: 45, room: "Studio B", mode: "offline", status: "scheduled", recurring: "weekly", color: "#2dbd7f",
  },
  {
    id: "c4", title: "Guitar Intermediate", instrument: "Guitar", teacher_id: "t2", teacher_name: t("t2").full_name,
    course_id: null, student_ids: ["s7"], start_time: iso(1, 9, 0), end_time: iso(1, 9, 45),
    duration_min: 45, room: "Room 2", mode: "offline", status: "scheduled", recurring: "weekly", color: "#2dbd7f",
  },
  {
    id: "c5", title: "Vocal Training", instrument: "Vocals", teacher_id: "t3", teacher_name: t("t3").full_name,
    course_id: null, student_ids: ["s4"], start_time: iso(0, 12, 0), end_time: iso(0, 12, 45),
    duration_min: 45, room: "Zoom", mode: "online", status: "scheduled", recurring: "weekly", color: "#e0608a",
  },
  {
    id: "c6", title: "Violin Essentials", instrument: "Violin", teacher_id: "t4", teacher_name: t("t4").full_name,
    course_id: null, student_ids: ["s6"], start_time: iso(1, 18, 0), end_time: iso(1, 18, 45),
    duration_min: 45, room: "Studio C", mode: "offline", status: "scheduled", recurring: "weekly", color: "#ff8f3f",
  },
  {
    id: "c7", title: "Drum Basics", instrument: "Drums", teacher_id: "t4", teacher_name: t("t4").full_name,
    course_id: null, student_ids: ["s5"], start_time: iso(2, 16, 0), end_time: iso(2, 16, 45),
    duration_min: 45, room: "Drum Room", mode: "offline", status: "scheduled", recurring: "weekly", color: "#5b8def",
  },
];

export const attendance: AttendanceRecord[] = [
  { id: "a1", class_id: "c1", student_id: "s1", status: "present", date: iso(-7, 17, 30) },
  { id: "a2", class_id: "c1", student_id: "s3", status: "present", date: iso(-7, 17, 30) },
  { id: "a3", class_id: "c1", student_id: "s1", status: "late", date: iso(-14, 17, 30) },
  { id: "a4", class_id: "c1", student_id: "s3", status: "absent", date: iso(-14, 17, 30) },
  { id: "a5", class_id: "c1", student_id: "s1", status: "present", date: iso(-21, 17, 30) },
];

export const practice: PracticeSession[] = [
  { id: "p1", student_id: "s1", instrument: "Piano", activity: "Scales & Arpeggios", minutes: 25, date: iso(0, 8, 0), notes: "Working on C major arpeggios", goal_met: true },
  { id: "p2", student_id: "s1", instrument: "Piano", activity: "Fur Elise", minutes: 30, date: iso(-1, 19, 0), notes: "Section B needs work", goal_met: true },
  { id: "p3", student_id: "s1", instrument: "Piano", activity: "Sight Reading", minutes: 15, date: iso(-2, 7, 30), goal_met: false },
  { id: "p4", student_id: "s1", instrument: "Piano", activity: "Scales & Arpeggios", minutes: 20, date: iso(-3, 18, 30), goal_met: true },
  { id: "p5", student_id: "s1", instrument: "Piano", activity: "Warm-up Exercises", minutes: 10, date: iso(-4, 8, 15), goal_met: false },
  { id: "p6", student_id: "s1", instrument: "Piano", activity: "Fur Elise", minutes: 35, date: iso(-5, 19, 30), goal_met: true },
  { id: "p7", student_id: "s2", instrument: "Guitar", activity: "Chord Changes", minutes: 20, date: iso(0, 9, 0) },
  { id: "p8", student_id: "s2", instrument: "Guitar", activity: "Strumming Patterns", minutes: 15, date: iso(-1, 10, 0) },
];

export const assignments: Assignment[] = [
  {
    id: "as1", title: "Master Fur Elise — Section A", description: "Play through Section A at a steady tempo. Focus on clean articulation.",
    instrument: "Piano", difficulty: "intermediate", due_date: iso(5, 20, 0), expected_minutes: 45,
    teacher_id: "t1", teacher_name: t("t1").full_name, student_id: "s1", status: "pending",
  },
  {
    id: "as2", title: "C Major Scales — Two octaves", description: "Both hands, hands together, at 90 bpm metronome.",
    instrument: "Piano", difficulty: "beginner", due_date: iso(3, 20, 0), expected_minutes: 30,
    teacher_id: "t1", teacher_name: t("t1").full_name, student_id: "s1", status: "submitted",
  },
  {
    id: "as3", title: "Review Assessment — Grade 3", description: "Prepare the three chosen pieces for next week's assessment.",
    instrument: "Piano", difficulty: "advanced", due_date: iso(7, 20, 0), expected_minutes: 60,
    teacher_id: "t1", teacher_name: t("t1").full_name, student_id: "s1", status: "pending",
  },
  {
    id: "as4", title: "Em Chord Transitions", description: "Practice A to Em transitions smoothly. Record a video.",
    instrument: "Guitar", difficulty: "beginner", due_date: iso(4, 19, 0), expected_minutes: 25,
    teacher_id: "t2", teacher_name: t("t2").full_name, student_id: "s2", status: "pending",
  },
];

export const resources: Resource[] = [
  { id: "r1", title: "Fur Elise — Sheet Music", instrument: "Piano", level: "Grade 3", type: "sheet_music", author: "Beethoven", favorite: true },
  { id: "r2", title: "C Major Scales Worksheet", instrument: "Piano", level: "All", type: "scales", author: "Swar Mangal", favorite: true },
  { id: "r3", title: "Warm-up Exercise #1", instrument: "Piano", level: "Beginner", type: "exercise", duration_min: 10, author: "Sarah Mitchell" },
  { id: "r4", title: "Basic Chord Progressions", instrument: "Guitar", level: "Beginner", type: "chords", author: "David Chen" },
  { id: "r5", title: "Ear Training — Intervals", instrument: "All", level: "Intermediate", type: "theory", duration_min: 15, author: "Swar Mangal" },
  { id: "r6", title: "Amazing Grace (Audio)", instrument: "Violin", level: "Grade 2", type: "audio", duration_min: 4, author: "Liam Nguyen", audio_url: "/audio/demo.wav" },
  { id: "r7", title: "Rhythm Counting Exercises", instrument: "All", level: "Grade 2", type: "exercise", author: "Sarah Mitchell" },
  { id: "r8", title: "Canon in D (Simplified)", instrument: "Piano", level: "Grade 4", type: "song", author: "Pachelbel" },
  { id: "r9", title: "Video Lesson — Posture", instrument: "Piano", level: "Beginner", type: "video", duration_min: 12, author: "Sarah Mitchell" },
];

export const skillCategories = [
  { name: "Technique", score: 78 },
  { name: "Rhythm", score: 65 },
  { name: "Sight Reading", score: 52 },
  { name: "Ear Training", score: 60 },
  { name: "Music Theory", score: 70 },
  { name: "Performance", score: 74 },
  { name: "Repertoire", score: 66 },
];

export const progress: Progress = {
  student_id: "s1",
  instrument: "Piano",
  level: "Grade 3",
  categories: skillCategories,
  overall: 67,
};

export const messages: Message[] = [
  { id: "m1", thread_id: "th1", sender_id: "t1", sender_name: t("t1").full_name, body: "Great progress today! Let's keep working on the arpeggios.", created_at: iso(0, 13, 30) },
  { id: "m2", thread_id: "th1", sender_id: "s1", sender_name: S("s1").full_name, body: "Thank you! I'll practice the E minor section tonight.", created_at: iso(0, 13, 45) },
  { id: "m3", thread_id: "th1", sender_id: "t1", sender_name: t("t1").full_name, body: "Perfect. See you Thursday for the assessment.", created_at: iso(0, 13, 50) },
];

export const threads: Thread[] = [
  { id: "th1", participant_ids: ["s1", "t1"], participant_names: [S("s1").full_name, t("t1").full_name], last_message: "Perfect. See you Thursday for the assessment.", last_message_at: iso(0, 13, 50), unread: 0, updated_at: iso(0, 13, 50) },
  { id: "th2", participant_ids: ["s1", "t2"], participant_names: [S("s1").full_name, t("t2").full_name], last_message: "Please send your scale video by Friday.", last_message_at: iso(-1, 10, 15), unread: 2, updated_at: iso(-1, 10, 15) },
];

export const notifications: NotificationItem[] = [
  { id: "n1", title: "Upcoming class", body: "Piano Fundamentals today at 5:30 PM", created_at: iso(0, 8, 0), read: false, type: "class" },
  { id: "n2", title: "Assignment feedback", body: "Sarah reviewed your C Major Scales assignment", created_at: iso(-1, 14, 0), read: false, type: "assignment" },
  { id: "n3", title: "Practice streak", body: "You've practiced 3 days in a row! Keep going.", created_at: iso(-1, 20, 0), read: true, type: "practice" },
  { id: "n4", title: "New announcement", body: "Recital registration now open for November.", created_at: iso(-2, 9, 0), read: true, type: "announcement" },
];

export const announcements: Announcement[] = [
  { id: "an1", title: "November Recital — Registration Open", body: "We're excited to announce our upcoming student recital. Register your slot by October 20.", author: "The Swar Mangal Team", created_at: iso(-2, 9, 0), audience: "All students", pinned: true },
  { id: "an2", title: "Holiday Notice — Diwali", body: "The academy will be closed from Oct 30 – Nov 1 for Diwali.", author: "Academy Office", created_at: iso(-5, 12, 0), audience: "All" },
  { id: "an3", title: "New Practice Challenge", body: "Complete 20 practice hours this quarter and earn a special badge!", author: "The Swar Mangal Team", created_at: iso(-9, 10, 0), audience: "All students" },
];

export const invoices: Invoice[] = [
  { id: "inv1", student_id: "s1", student_name: S("s1").full_name, amount: 120, status: "paid", due_date: iso(10, 0), issued_date: iso(-20, 0), description: "Monthly tuition — October" },
  { id: "inv2", student_id: "s2", student_name: S("s2").full_name, amount: 120, status: "pending", due_date: iso(15, 0), issued_date: iso(-5, 0), description: "Monthly tuition — October" },
  { id: "inv3", student_id: "s4", student_name: S("s4").full_name, amount: 120, status: "overdue", due_date: iso(-5, 0), issued_date: iso(-25, 0), description: "Monthly tuition — September" },
  { id: "inv4", student_id: "s10", student_name: S("s10").full_name, amount: 150, status: "paid", due_date: iso(12, 0), issued_date: iso(-3, 0), description: "Monthly tuition — October" },
];

export const payments = [
  { id: "pay1", student_name: S("s1").full_name, amount: 120, method: "Card", date: iso(-3, 0), status: "paid" },
  { id: "pay2", student_name: S("s10").full_name, amount: 150, method: "UPI", date: iso(-2, 0), status: "paid" },
  { id: "pay3", student_name: S("s5").full_name, amount: 130, method: "Bank transfer", date: iso(-1, 0), status: "paid" },
];

export const achievements: Achievement[] = [
  { id: "ach1", title: "7-Day Streak", description: "Practiced for 7 days in a row", icon: "Flame", earned_at: iso(-3, 0), student_id: "s1" },
  { id: "ach2", title: "10 Hours Practiced", description: "Reached 10 total practice hours", icon: "Clock", earned_at: iso(-10, 0), student_id: "s1" },
  { id: "ach3", title: "First Assessment Passed", description: "Passed Grade 2 assessment with distinction", icon: "Trophy", earned_at: iso(-40, 0), student_id: "s1" },
];

export const feedback: Feedback[] = [
  { id: "fb1", student_id: "s1", teacher_id: "t1", teacher_name: t("t1").full_name, body: "Great progress on arpeggios! Keep your wrist relaxed and focus on even tempo.", created_at: iso(-1, 13, 0), category: "Technique" },
  { id: "fb2", student_id: "s1", teacher_id: "t1", teacher_name: t("t1").full_name, body: "Excellent rhythm on the sight-reading today. Try tapping your foot to keep time.", created_at: iso(-4, 12, 30), category: "Rhythm" },
];

export const activity: ActivityItem[] = [
  { id: "act1", type: "lesson", title: "Lesson completed", detail: "Piano Fundamentals with Sarah Mitchell", created_at: iso(-1, 18, 15) },
  { id: "act2", type: "assignment", title: "Assignment submitted", detail: "C Major Scales — Two octaves", created_at: iso(-1, 19, 40) },
  { id: "act3", type: "practice", title: "Practice session", detail: "30 min — Fur Elise", created_at: iso(-1, 19, 30) },
  { id: "act4", type: "feedback", title: "Teacher feedback", detail: "Sarah left feedback on your performance", created_at: iso(-1, 13, 0) },
];

export const attendanceStatusLegend: AttendanceStatus[] = ["present", "absent", "late", "excused"];

export const weeklyHours = [18, 32, 0, 25, 40, 30, 22];
