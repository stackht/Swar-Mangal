-- Swar Mangal Academy — PostgreSQL schema (Railway-compatible)
-- Plain Postgres: no auth.users, no RLS, no auth.uid(). Runs on Railway Postgres via psql.

create extension if not exists pgcrypto;

-- ============ ENUMS ============
do $$ begin
  create type user_role as enum ('admin', 'teacher', 'student', 'parent');
exception when duplicate_object then null; end $$;
do $$ begin
  create type attendance_status as enum ('present', 'absent', 'late', 'excused');
exception when duplicate_object then null; end $$;
do $$ begin
  create type class_status as enum ('scheduled', 'completed', 'cancelled');
exception when duplicate_object then null; end $$;
do $$ begin
  create type class_mode as enum ('online', 'offline');
exception when duplicate_object then null; end $$;
do $$ begin
  create type assignment_status as enum ('pending', 'submitted', 'reviewed', 'overdue');
exception when duplicate_object then null; end $$;
do $$ begin
  create type difficulty as enum ('beginner', 'intermediate', 'advanced');
exception when duplicate_object then null; end $$;
do $$ begin
  create type resource_type as enum ('sheet_music', 'exercise', 'scales', 'chords', 'theory', 'song', 'audio', 'video', 'lesson');
exception when duplicate_object then null; end $$;
do $$ begin
  create type payment_status as enum ('paid', 'pending', 'overdue', 'partial');
exception when duplicate_object then null; end $$;

-- ============ USERS (replaces auth.users) ============
create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  password_hash text not null,
  role user_role not null default 'student',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists user_sessions (
  token_hash text primary key,
  user_id uuid not null references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

-- ============ PROFILES ============
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  email text not null,
  full_name text not null,
  role user_role not null default 'student',
  avatar_url text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ INSTRUMENTS ============
create table if not exists instruments (
  id text primary key,
  name text not null unique,
  icon text,
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ COURSES ============
create table if not exists courses (
  id text primary key,
  name text not null,
  instrument_id text references instruments(id) on delete set null,
  level text not null default 'Beginner',
  description text,
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ TEACHERS / STUDENTS / PARENTS ============
create table if not exists teachers (
  id text primary key,
  profile_id uuid references profiles(id) on delete cascade,
  full_name text not null,
  email text not null,
  avatar_url text,
  phone text,
  instrument text,
  rating numeric(2,1) default 0
);

create table if not exists parents (
  id text primary key,
  profile_id uuid references profiles(id) on delete cascade,
  full_name text not null,
  email text not null,
  avatar_url text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists students (
  id text primary key,
  profile_id uuid references profiles(id) on delete cascade,
  full_name text not null,
  email text not null,
  avatar_url text,
  phone text,
  instrument text,
  level text default 'Beginner',
  parent_id text references parents(id) on delete set null,
  fee_status payment_status default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ CLASSES / SCHEDULES ============
create table if not exists classes (
  id text primary key,
  title text not null,
  instrument text,
  teacher_id text references teachers(id) on delete set null,
  teacher_name text,
  course_id text references courses(id) on delete set null,
  room text,
  mode class_mode default 'offline',
  status class_status default 'scheduled',
  recurring text,
  start_time timestamptz not null,
  end_time timestamptz not null,
  duration_min int,
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_classes_start on classes(start_time);
create index if not exists idx_classes_teacher on classes(teacher_id);
create index if not exists idx_classes_status on classes(status);

create table if not exists class_students (
  class_id text references classes(id) on delete cascade,
  student_id text references students(id) on delete cascade,
  primary key (class_id, student_id)
);

-- ============ ATTENDANCE ============
create table if not exists attendance (
  id text primary key,
  class_id text references classes(id) on delete cascade,
  student_id text references students(id) on delete cascade,
  status attendance_status not null default 'present',
  date timestamptz not null default now(),
  marked_by text references teachers(id),
  created_at timestamptz not null default now(),
  unique (class_id, student_id, date)
);

create index if not exists idx_attendance_student on attendance(student_id, date);

-- ============ PRACTICE ============
create table if not exists practice_sessions (
  id text primary key,
  student_id text references students(id) on delete cascade not null,
  instrument text,
  activity text not null,
  minutes int not null,
  date timestamptz not null default now(),
  notes text,
  goal_met boolean default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_practice_student_date on practice_sessions(student_id, date desc);

-- ============ ASSIGNMENTS ============
create table if not exists assignments (
  id text primary key,
  title text not null,
  description text,
  instrument text,
  difficulty difficulty default 'beginner',
  due_date timestamptz not null,
  expected_minutes int default 30,
  teacher_id text references teachers(id) on delete set null not null,
  teacher_name text,
  student_id text references students(id) on delete cascade not null,
  status assignment_status default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_assignments_student on assignments(student_id, due_date);
create index if not exists idx_assignments_teacher on assignments(teacher_id);

create table if not exists assignment_submissions (
  id text primary key,
  assignment_id text references assignments(id) on delete cascade unique,
  student_id text references students(id) on delete cascade,
  body text,
  attachment_url text,
  submitted_at timestamptz not null default now()
);

-- ============ LEARNING RESOURCES ============
create table if not exists learning_resources (
  id text primary key,
  title text not null,
  instrument text,
  level text,
  type resource_type not null default 'lesson',
  duration_min int,
  author text,
  author_id text,
  audio_url text,
  file_url text,
  favorite boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ PROGRESS ============
create table if not exists progress_categories (
  id text primary key,
  name text unique not null
);

create table if not exists progress (
  id text primary key,
  student_id text references students(id) on delete cascade not null,
  category text not null,
  score int not null default 0 check (score >= 0 and score <= 100),
  instrument text,
  level text,
  recorded_at timestamptz not null default now(),
  unique (student_id, category)
);

create table if not exists teacher_feedback (
  id text primary key,
  student_id text references students(id) on delete cascade not null,
  teacher_id text references teachers(id) on delete set null,
  teacher_name text,
  category text,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists achievements (
  id text primary key,
  student_id text references students(id) on delete cascade not null,
  title text not null,
  description text,
  icon text,
  earned_at timestamptz not null default now()
);

-- ============ MESSAGING ============
create table if not exists message_threads (
  id text primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists message_participants (
  thread_id text references message_threads(id) on delete cascade,
  participant_name text,
  participant_id text,
  unread_count int default 0,
  primary key (thread_id, participant_name)
);

create table if not exists messages (
  id text primary key,
  thread_id text references message_threads(id) on delete cascade not null,
  sender_id text,
  sender_name text not null,
  body text not null,
  attachment_url text,
  created_at timestamptz not null default now()
);

create index if not exists idx_messages_thread on messages(thread_id, created_at);

-- ============ NOTIFICATIONS ============
create table if not exists notifications (
  id text primary key,
  user_id text,
  title text not null,
  body text,
  type text default 'general',
  read boolean default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user on notifications(user_id, created_at desc);

-- ============ ANNOUNCEMENTS ============
create table if not exists announcements (
  id text primary key,
  title text not null,
  body text,
  author text,
  audience text default 'all',
  pinned boolean default false,
  created_at timestamptz not null default now()
);

-- ============ PAYMENTS ============
create table if not exists invoices (
  id text primary key,
  student_id text references students(id) on delete cascade not null,
  student_name text,
  description text,
  amount numeric(10,2) not null check (amount >= 0),
  status payment_status default 'pending',
  issued_date timestamptz not null default now(),
  due_date timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists payments (
  id text primary key,
  invoice_id text references invoices(id) on delete set null,
  student_name text,
  amount numeric(10,2) not null,
  method text,
  transaction_id text,
  status payment_status default 'paid',
  paid_at timestamptz not null default now()
);

create index if not exists idx_invoices_student on invoices(student_id, status);