# Swar Mangal — Music Academy Management Platform

Premium music class management platform for students, teachers, and academies.

## Features

**Student**
- Dashboard with next-class countdown, quick actions, practice summary, progress rings, assignments, activity feed, achievements
- Class schedule with week navigation
- Practice tracker with animated timer, weekly chart, streak, session history
- Assignments: submit, attach, track status
- Learning library with search, filters, favorites
- Music-specific progress: 7 skill categories, trend chart, teacher feedback
- Attendance history, fees/invoices, messaging, notifications

**Teacher**
- Dashboard: today's classes timeline, student attention, quick actions
- Students: per-student practice tracking, overall skill score, one-click feedback dialog
- Attendance: bulk roll marking (present/absent/late/excused)
- Assignments: review, grade, feedback, request revision
- Practice tracking per student with weekly goals
- Learning materials manager, schedule, messaging, progress charts

**Admin**
- SaaS dashboard: student growth / attendance / revenue charts
- Students/Teachers/Courses/Instruments CRUD
- Schedule with week view and class counts
- Fees & payments: invoices, payment recording, outstanding balances
- Announcements publisher, analytics (instrument mix, class utilization), settings

**Parent**
- Dashboard: child's practice, attendance, skill score, fee status
- Attendance, progress, messaging, notifications

## Tech Stack

- Next.js 15 (App Router) + React 19 + TypeScript (strict)
- Tailwind CSS design system with HSL color tokens, dark mode via `next-themes`
- Radix UI primitives, Lucide icons, Framer Motion animations
- React Hook Form + Zod (forms), TanStack Query (server state)
- Recharts (analytics), date-fns (dates)
- Supabase (PostgreSQL + Auth + RLS + Storage), installable PWA

## Quick Start

The app runs in **demo mode** out of the box — no credentials needed. Pick a role on the login screen to explore fully functional dashboards backed by realistic demo data.

```bash
npm install
npm run dev
# http://localhost:3000
```

### Connect Supabase (production)

1. Create a project at [supabase.com](https://supabase.com).
2. Run `supabase/schema.sql` in the SQL editor.
3. Set env vars:

```bash
cp .env.example .env.local
```

```env
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

4. Enable the signup trigger in `auth.users` → new users get a `profiles` row and role via `raw_user_meta_data.role`.

## Project Structure

```
app/
  (auth)/          login, auth layout
  (dashboard)/     student/, teacher/, admin/, parent/ — role-guarded layouts
components/
  ui/              button, card, dialog, dropdown, tabs, input, progress, toast, etc.
  dashboard/       app-shell, sidebar, header, bottom-nav, stat-card, gradient-card, class-card, messages-view
  practice/        practice-timer
lib/
  data/demo.ts     realistic demo data (students, classes, practice, invoices…)
  utils/           cn, date/time helpers
  supabase/        client + typed client
types/
  index.ts         shared domain types
supabase/
  schema.sql       full PostgreSQL schema + RLS policies
public/
  manifest.json    PWA manifest
```

## Scripts

- `npm run dev` — development server
- `npm run build` — production build (runs ESLint + type checking)
- `npm run typecheck` — TypeScript strict check
- `npm run lint` — ESLint

## Design System

- Warm neutral background (`hsl 220 33% 98%`), deep navy primary (`222 45% 11%`)
- Pastel accents: lavender / mint / peach / sky
- 20px base card radius, soft shadows, glass blurs, subtle gradients
- Framer Motion: page transitions, card hover lift, staggered list entrances, animated progress, timer ticks, layout-animated navigation — all respecting `prefers-reduced-motion`

## Demo Accounts

Login page offers **Admin**, **Teacher**, and **Student** demo entry points. A parent option is also available. All data lives in `src/lib/data/demo.ts` and is fully interactive (attendance marking, practice logging, submissions, invoice creation all persist client-side for the session).