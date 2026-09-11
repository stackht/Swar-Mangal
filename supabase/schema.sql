-- Maestro — Music Academy Database Schema
-- PostgreSQL + Supabase. Run in the Supabase SQL editor.

create extension if not exists "pgcrypto";

-- ============ ENUMS ============
create type user_role as enum ('admin', 'teacher', 'student', 'parent');
create type attendance_status as enum ('present', 'absent', 'late', 'excused');
create type class_status as enum ('scheduled', 'completed', 'cancelled');
create type class_mode as enum ('online', 'offline');
create type assignment_status as enum ('pending', 'submitted', 'reviewed', 'overdue');
create type difficulty as enum ('beginner', 'intermediate', 'advanced');
create type resource_type as enum ('sheet_music', 'exercise', 'scales', 'chords', 'theory', 'song', 'audio', 'video', 'lesson');
create type payment_status as enum ('paid', 'pending', 'overdue', 'partial');

-- ============ PROFILES ============
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  role user_role not null default 'student',
  avatar_url text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ INSTRUMENTS ============
create table instruments (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text,
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ COURSES ============
create table courses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  instrument_id uuid references instruments(id) on delete set null,
  level text not null default 'Beginner',
  description text,
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ TEACHERS / STUDENTS / PARENTS ============
create table teachers (
  id uuid primary key references profiles(id) on delete cascade,
  instrument text,
  rating numeric(2,1) default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table parents (
  id uuid primary key references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table students (
  id uuid primary key references profiles(id) on delete cascade,
  instrument text,
  level text default 'Beginner',
  parent_id uuid references parents(id) on delete set null,
  fee_status payment_status default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ CLASSES / SCHEDULES ============
create table classes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  instrument text,
  teacher_id uuid references teachers(id) on delete set null,
  course_id uuid references courses(id) on delete set null,
  room text,
  mode class_mode default 'offline',
  status class_status default 'scheduled',
  recurring text, -- 'weekly', 'biweekly', null
  start_time timestamptz not null,
  end_time timestamptz not null,
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_classes_start on classes(start_time);
create index idx_classes_teacher on classes(teacher_id);
create index idx_classes_status on classes(status);

create table class_students (
  class_id uuid references classes(id) on delete cascade,
  student_id uuid references students(id) on delete cascade,
  primary key (class_id, student_id)
);

-- ============ ATTENDANCE ============
create table attendance (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references classes(id) on delete cascade,
  student_id uuid references students(id) on delete cascade,
  status attendance_status not null default 'present',
  date timestamptz not null default now(),
  marked_by uuid references teachers(id),
  created_at timestamptz not null default now(),
  unique (class_id, student_id, date)
);

create index idx_attendance_student on attendance(student_id, date);

-- ============ PRACTICE ============
create table practice_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade not null,
  instrument text,
  activity text not null,
  minutes int not null,
  date timestamptz not null default now(),
  notes text,
  goal_met boolean default false,
  created_at timestamptz not null default now()
);

create index idx_practice_student_date on practice_sessions(student_id, date desc);

-- ============ ASSIGNMENTS ============
create table assignments (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  instrument text,
  difficulty difficulty default 'beginner',
  due_date timestamptz not null,
  expected_minutes int default 30,
  teacher_id uuid references teachers(id) on delete set null not null,
  student_id uuid references students(id) on delete cascade not null,
  status assignment_status default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_assignments_student on assignments(student_id, due_date);
create index idx_assignments_teacher on assignments(teacher_id);

create table assignment_submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid references assignments(id) on delete cascade unique,
  student_id uuid references students(id) on delete cascade,
  body text,
  attachment_url text,
  submitted_at timestamptz not null default now()
);

-- ============ LEARNING RESOURCES ============
create table learning_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  instrument text,
  level text,
  type resource_type not null default 'lesson',
  duration_min int,
  author text,
  author_id uuid references profiles(id) on delete set null,
  audio_url text,
  file_url text,
  favorite boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ PROGRESS ============
create table progress_categories (
  id uuid primary key default gen_random_uuid(),
  name text unique not null
);

create table progress (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade not null,
  category_id uuid references progress_categories(id) on delete cascade not null,
  score int not null default 0 check (score >= 0 and score <= 100),
  instrument text,
  level text,
  recorded_at timestamptz not null default now(),
  unique (student_id, category_id)
);

create table teacher_feedback (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade not null,
  teacher_id uuid references teachers(id) on delete set null,
  category text,
  body text not null,
  created_at timestamptz not null default now()
);

create table achievements (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade not null,
  title text not null,
  description text,
  icon text,
  earned_at timestamptz not null default now()
);

-- ============ MESSAGING ============
create table message_threads (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table message_participants (
  thread_id uuid references message_threads(id) on delete cascade,
  profile_id uuid references profiles(id) on delete cascade,
  unread_count int default 0,
  primary key (thread_id, profile_id)
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid references message_threads(id) on delete cascade not null,
  sender_id uuid references profiles(id) on delete cascade not null,
  body text not null,
  attachment_url text,
  created_at timestamptz not null default now()
);

create index idx_messages_thread on messages(thread_id, created_at);

-- ============ NOTIFICATIONS ============
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade not null,
  title text not null,
  body text,
  type text default 'general',
  read boolean default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_user on notifications(user_id, created_at desc);

-- ============ ANNOUNCEMENTS ============
create table announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text,
  author text,
  audience text default 'all',
  pinned boolean default false,
  created_at timestamptz not null default now()
);

-- ============ PAYMENTS ============
create table invoices (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade not null,
  description text,
  amount numeric(10,2) not null check (amount >= 0),
  status payment_status default 'pending',
  issued_date timestamptz not null default now(),
  due_date timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid references invoices(id) on delete set null,
  student_id uuid references students(id) on delete cascade not null,
  amount numeric(10,2) not null,
  method text,
  transaction_id text,
  status payment_status default 'paid',
  paid_at timestamptz not null default now()
);

create index idx_invoices_student on invoices(student_id, status);
create index idx_payments_student on payments(student_id, paid_at);

-- ============ TRIGGERS: updated_at ============
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_profiles_updated before update on profiles for each row execute function set_updated_at();
create trigger trg_students_updated before update on students for each row execute function set_updated_at();
create trigger trg_teachers_updated before update on teachers for each row execute function set_updated_at();
create trigger trg_classes_updated before update on classes for each row execute function set_updated_at();
create trigger trg_courses_updated before update on courses for each row execute function set_updated_at();
create trigger trg_lr_updated before update on learning_resources for each row execute function set_updated_at();
create trigger trg_assignments_updated before update on assignments for each row execute function set_updated_at();
create trigger trg_invoices_updated before update on invoices for each row execute function set_updated_at();

-- ============ AUTO-CREATE PROFILE ON SIGNUP ============
create or replace function public.handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'student')
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============ ROW LEVEL SECURITY ============
alter table profiles enable row level security;
alter table instruments enable row level security;
alter table courses enable row level security;
alter table teachers enable row level security;
alter table parents enable row level security;
alter table students enable row level security;
alter table classes enable row level security;
alter table class_students enable row level security;
alter table attendance enable row level security;
alter table practice_sessions enable row level security;
alter table assignments enable row level security;
alter table assignment_submissions enable row level security;
alter table learning_resources enable row level security;
alter table progress_categories enable row level security;
alter table progress enable row level security;
alter table teacher_feedback enable row level security;
alter table achievements enable row level security;
alter table message_threads enable row level security;
alter table message_participants enable row level security;
alter table messages enable row level security;
alter table notifications enable row level security;
alter table announcements enable row level security;
alter table invoices enable row level security;
alter table payments enable row level security;

-- helper: is the requesting user an admin (or has service role)
create or replace function public.is_admin() returns boolean as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$ language sql stable security definer set search_path = public;

-- helper: is requesting user the teacher for a class
create or replace function public.is_class_teacher(class_id uuid) returns boolean as $$
  select exists (
    select 1 from public.classes c
    where c.id = is_class_teacher.class_id and c.teacher_id = auth.uid()
  );
$$ language sql stable security definer set search_path = public;

-- ---- profiles: users read their own; admins read all ----
create policy "own profile" on profiles for select using (id = auth.uid() or public.is_admin());
create policy "update own profile" on profiles for update using (id = auth.uid() or public.is_admin());
create policy "insert profile" on profiles for insert with check (id = auth.uid() or public.is_admin());

-- ---- read-mostly reference tables ----
create policy "instruments readable" on instruments for select using (true);
create policy "courses readable" on courses for select using (true);
create policy "progress categories readable" on progress_categories for select using (true);

-- ---- students ----
create policy "students readable by staff or self" on students for select using (
  public.is_admin() or (select role = 'teacher' from profiles where id = auth.uid()) or id = auth.uid()
);
create policy "students managed by admin" on students for all using (public.is_admin());

-- ---- teachers ----
create policy "teachers readable" on teachers for select using (
  public.is_admin() or (select role in ('teacher','student','parent') from profiles where id = auth.uid())
);
create policy "teachers managed by admin" on teachers for all using (public.is_admin());

-- ---- classes ----
create policy "classes visible" on classes for select using (
  public.is_admin()
  or teacher_id = auth.uid()
  or exists (select 1 from class_students cs where cs.class_id = classes.id and cs.student_id = auth.uid())
);
create policy "classes managed by staff" on classes for all using (public.is_admin() or teacher_id = auth.uid());

-- ---- class_students ----
create policy "class students visible" on class_students for select using (
  public.is_admin()
  or exists (select 1 from classes c where c.id = class_students.class_id and c.teacher_id = auth.uid())
  or student_id = auth.uid()
);

-- ---- attendance ----
create policy "attendance visible" on attendance for select using (
  public.is_admin()
  or marked_by = auth.uid()
  or student_id = auth.uid()
  or exists (select 1 from classes c join class_students cs on cs.class_id = c.id where cs.student_id = attendance.student_id and c.teacher_id = auth.uid())
);
create policy "attendance managed by teacher" on attendance for all using (public.is_admin() or public.is_class_teacher(class_id));

-- ---- practice ----
create policy "own practice" on practice_sessions for select using (student_id = auth.uid() or public.is_admin());
create policy "record own practice" on practice_sessions for insert with check (student_id = auth.uid());
-- teachers may view practice of their students
create policy "teacher sees practice" on practice_sessions for select using (
  exists (
    select 1 from classes c join class_students cs on cs.class_id = c.id
    where cs.student_id = practice_sessions.student_id and c.teacher_id = auth.uid()
  )
);

-- ---- assignments ----
create policy "assignments visible" on assignments for select using (
  student_id = auth.uid() or teacher_id = auth.uid() or public.is_admin()
);
create policy "teachers create assignments" on assignments for insert with check (
  teacher_id = auth.uid() or public.is_admin()
);
create policy "teachers update assignments" on assignments for update using (
  teacher_id = auth.uid() or public.is_admin()
);
create policy "assignments managed by admin" on assignments for delete using (public.is_admin());

-- ---- assignment submissions ----
create policy "submissions visible" on assignment_submissions for select using (
  student_id = auth.uid()
  or public.is_admin()
  or exists (select 1 from assignments a where a.id = assignment_submissions.assignment_id and a.teacher_id = auth.uid())
);
create policy "submit own work" on assignment_submissions for insert with check (student_id = auth.uid());

-- ---- learning resources ----
create policy "resources readable" on learning_resources for select using (true);
create policy "staff manage resources" on learning_resources for all using (public.is_admin() or (select role = 'teacher' from profiles where id = auth.uid()));

-- ---- progress + feedback ----
create policy "progress visible" on progress for select using (
  student_id = auth.uid()
  or public.is_admin()
  or exists (select 1 from classes c join class_students cs on cs.class_id = c.id where cs.student_id = progress.student_id and c.teacher_id = auth.uid())
);
create policy "teachers record progress" on progress for all using (
  public.is_admin()
  or exists (select 1 from classes c join class_students cs on cs.class_id = c.id where cs.student_id = progress.student_id and c.teacher_id = auth.uid())
);

create policy "feedback visible" on teacher_feedback for select using (
  student_id = auth.uid() or teacher_id = auth.uid() or public.is_admin()
);
create policy "teachers give feedback" on teacher_feedback for insert with check (teacher_id = auth.uid() or public.is_admin());

-- ---- achievements ----
create policy "achievements visible" on achievements for select using (
  student_id = auth.uid() or public.is_admin()
  or exists (select 1 from classes c join class_students cs on cs.class_id = c.id where cs.student_id = achievements.student_id and c.teacher_id = auth.uid())
);

-- ---- messaging: participants only ----
create policy "threads visible to participants" on message_threads for select using (
  exists (select 1 from message_participants mp where mp.thread_id = message_threads.id and mp.profile_id = auth.uid())
);

create policy "messages visible to participants" on messages for select using (
  exists (select 1 from message_participants mp where mp.thread_id = messages.thread_id and mp.profile_id = auth.uid())
);
create policy "send message" on messages for insert with check (
  sender_id = auth.uid()
  and exists (select 1 from message_participants mp where mp.thread_id = messages.thread_id and mp.profile_id = auth.uid())
);

-- ---- notifications: owner only ----
create policy "own notifications" on notifications for all using (user_id = auth.uid());

-- ---- announcements: readable by all, write by admin ----
create policy "announcements readable" on announcements for select using (true);
create policy "announcements managed by admin" on announcements for all using (public.is_admin());

-- ---- payments: own invoices/payments, staff managing ----
create policy "invoices visible" on invoices for select using (
  student_id = auth.uid() or public.is_admin()
  or exists (select 1 from class_students cs join classes c on c.id = cs.class_id where cs.student_id = invoices.student_id and c.teacher_id = auth.uid())
);
create policy "invoices managed by admin" on invoices for all using (public.is_admin());

create policy "payments visible" on payments for select using (
  student_id = auth.uid() or public.is_admin()
);
create policy "payments recorded by admin" on payments for insert with check (public.is_admin());