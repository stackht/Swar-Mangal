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

create unique index if not exists idx_profiles_user on profiles(user_id);

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
  student_id text not null,
  instrument text,
  activity text not null,
  minutes int not null,
  date timestamptz not null default now(),
  notes text,
  goal_met boolean default false,
  created_at timestamptz not null default now()
);

-- drop legacy FK so real AcademyOS student ids (students_acad) can be referenced
alter table practice_sessions drop constraint if exists practice_sessions_student_id_fkey;

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

-- ============ ACADEMYOS MIRROR TABLES (real ERP data import) ============

create table if not exists entities (
  id text primary key,
  code text,
  name text,
  entity_type text,
  address text,
  active boolean default true
);

create table if not exists teachers_acad (
  id text primary key,
  name text,
  phone text,
  email text,
  instrument text,
  status text
);

create table if not exists students_acad (
  id text primary key,
  name text,
  guardian_name text,
  phone text,
  email text,
  instrument text,
  branch text,
  batch text,
  fee_plan text,
  status text,
  enrollment_date date,
  notes text
);

create table if not exists packages (
  id text primary key,
  entity_code text,
  course text,
  name text,
  package_type text,
  billing_type text,
  fee_amount numeric(10,2)
);

create table if not exists student_packages (
  id text primary key,
  student_id text,
  student_name text,
  course text,
  teacher_id text,
  receipt_no text,
  fee_amount numeric(10,2),
  cycle_start date,
  cycle_end date
);

create table if not exists receipts (
  id text primary key,
  receipt_no text,
  party_name text,
  amount numeric(10,2),
  status text,
  payment_mode text,
  linked_url text,
  record_id text
);

create table if not exists money_ledger (
  id text primary key,
  entry_date date,
  party_name text,
  category text,
  description text,
  inflow numeric(10,2),
  outflow numeric(10,2),
  amount numeric(10,2),
  payment_mode text,
  account text,
  status text
);

create table if not exists expenses (
  id text primary key,
  expense_date date,
  category text,
  vendor text,
  description text,
  amount numeric(10,2),
  approval_status text
);

create table if not exists attendance_acad (
  id text primary key,
  session_date date,
  student_id text,
  student_name text,
  teacher_id text,
  teacher_name text,
  instrument text,
  status text
);

create table if not exists inquiries (
  id text primary key,
  name text,
  phone text,
  instrument text,
  branch text,
  source text,
  notes text,
  status text,
  created_at date
);

create table if not exists payout_rules (
  id text primary key,
  teacher_id text,
  teacher_name text,
  entity_id text,
  course text,
  payout_type text,
  percentage numeric(5,2)
);

create table if not exists school_compensation (
  id text primary key,
  teacher_id text,
  teacher_name text,
  school_id text,
  courses text,
  monthly_amount numeric(10,2),
  payout_type text,
  status text
);

create table if not exists schools (
  id text primary key,
  name text,
  address text,
  entity_id text,
  active boolean default true
);

-- ============ RPC SUPPORT TABLES (standalone gateway) ============

create table if not exists payment_drafts (
  id text primary key,
  status text not null default 'SUBMITTED',
  student_id text,
  student_name text,
  amount numeric(10,2) not null,
  payment_mode text,
  branch text,
  terms_status text default '',
  projected_next_due_date text,
  repair_required boolean default false,
  submitted_by text,
  submitted_at timestamptz not null default now(),
  approval_authority text default '',
  approved_by text default '',
  approved_at timestamptz,
  finalised_receipt_no text,
  finalised_at timestamptz
);

create table if not exists timetable (
  id text primary key,
  branch text not null,
  day_of_week int not null,
  start_time text not null,
  end_time text not null,
  class_name text not null,
  teacher_id text,
  teacher_name text,
  status text default 'ENABLED'
);

create table if not exists scheduled_sessions (
  id text primary key,
  session_date text,
  start_time text,
  teacher_id text,
  teacher_name text,
  branch text,
  course text,
  outcome text default '',
  delivered_by text default '',
  payee_teacher_id text default '',
  recorded_by text default '',
  evidence_class text default '',
  evidence_reason text default '',
  not_required boolean default false,
  closure_reason text default '',
  custom_kind text default '',
  custom_reason text default '',
  resolved boolean default false,
  answerable boolean default true,
  created_at timestamptz not null default now()
);

create table if not exists school_invoices_rpc (
  id text primary key,
  invoice_no text,
  invoice_date text,
  branch text,
  class_name text,
  amount numeric(10,2),
  tenure text,
  status text default 'FINAL',
  created_at timestamptz not null default now()
);
-- ============ BRANCH OWNERSHIP + DOCUMENT NUMBERING ============

-- Branch/student ownership on money rows so staff scope can be enforced
-- from stored data (backfilled once by db/apply.mjs migrations).
alter table receipts add column if not exists student_id text;
alter table receipts add column if not exists branch text;
alter table money_ledger add column if not exists branch text;

-- One row per numbering series (e.g. SMR-26-27). Incremented inside the
-- same transaction that writes the document, so numbers never repeat.
create table if not exists doc_counters (
  series text primary key,
  last_no int not null
);

-- One-time data migrations applied by db/apply.mjs.
create table if not exists schema_migrations (
  id text primary key,
  applied_at timestamptz not null default now()
);

-- Receipt timestamp: the app used to derive a "date" from the row id.
alter table receipts add column if not exists created_at timestamptz;

-- Revision counters powering api_syncChanges. Bumped by every write handler;
-- clients poll for the entities whose revision moved.
create table if not exists entity_revisions (
  entity text primary key,
  revision bigint not null default 1,
  updated_at timestamptz not null default now()
);

create index if not exists idx_receipts_student on receipts (student_id);
create index if not exists idx_receipts_party on receipts (party_name);
create index if not exists idx_attendance_acad_student on attendance_acad (student_id);
create index if not exists idx_money_ledger_entry_date on money_ledger (entry_date);

-- Fee plan + cycle per student (imported from the AcademyOS sheet, then
-- maintained by the app on each payment). Null means "not recorded yet";
-- the apps show that honestly instead of assuming a due date.
alter table students_acad add column if not exists fee_plan_name text;
alter table students_acad add column if not exists monthly_fee numeric(10,2);
alter table students_acad add column if not exists fee_cycle_months int;
alter table students_acad add column if not exists fee_due_day int;
alter table students_acad add column if not exists next_due_date date;
alter table students_acad add column if not exists cycle_start date;
alter table students_acad add column if not exists cycle_end date;
alter table students_acad add column if not exists last_payment_date date;

create index if not exists idx_students_acad_next_due on students_acad (next_due_date);

-- ============ DEVICE TOKENS + AUDIT TRAIL ============

-- One row per issued device token. The token itself is never stored, only
-- its SHA-256. Revoke a lost phone by setting revoked_at.
create table if not exists device_tokens (
  id text primary key,
  token_hash text not null unique,
  role text not null,
  label text not null,
  email text,
  branches text,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  revoked_at timestamptz
);

-- Who did what. Ids only: no names, amounts or phone numbers.
create table if not exists audit_log (
  id bigserial primary key,
  at timestamptz not null default now(),
  actor_role text,
  actor_email text,
  device_label text,
  fn text not null,
  ok boolean not null,
  code text,
  branch text,
  ref text
);

create index if not exists idx_audit_log_at on audit_log (at desc);
