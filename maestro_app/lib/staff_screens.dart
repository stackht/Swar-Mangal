import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

// ---------- Shared page scaffold for staff ----------

class _Page extends StatelessWidget {
  const _Page({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: children,
      ),
    );
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

// ================= TEACHER =================

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    final today = allLessons
        .where((l) =>
            l.start.year == DateTime.now().year &&
            l.start.month == DateTime.now().month &&
            l.start.day == DateTime.now().day)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return _Page(
      children: [
        Row(children: [
          const IconChip(icon: Icons.music_note_rounded, color: Palette.mint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$_greeting(), Sarah.',
                  style: const TextStyle(
                      color: Palette.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              Text('${today.length} classes today',
                  style: const TextStyle(color: Palette.muted, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: StatTile(label: 'Classes today', value: '${today.length}', accent: Palette.lavender)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'My students', value: '${teacherStudentNames.length}', accent: Palette.mint)),
        ]),
        const SectionTitle("Today's classes"),
        if (today.isEmpty)
          const _EmptyInline('No classes today — enjoy the break.')
        else
          for (final l in today) _TeacherLessonRow(l),
        const SectionTitle('Students · weekly practice'),
        for (final name in teacherStudentNames)
          _StudentPracticeRow(name, teacherPractice[name] ?? 0),
        const SectionTitle('To review'),
        AppCard(
          child: Row(children: [
            const IconChip(icon: Icons.task_alt_rounded, color: Palette.peach),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('2 assignments awaiting review',
                    style: TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                const Text('C Major Scales · Fur Elise', style: TextStyle(color: Palette.muted, fontSize: 11)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class TeacherStudentsScreen extends StatelessWidget {
  const TeacherStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        const Text('My Students',
            style: TextStyle(color: Palette.text, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
        const SizedBox(height: 16),
        for (final name in teacherStudentNames)
          _StudentPracticeRow(name, teacherPractice[name] ?? 0),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _TeacherLessonRow extends StatelessWidget {
  const _TeacherLessonRow(this.lesson);
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Palette.lavender.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text(fmtTime(lesson.start).split(' ')[0],
                  style: const TextStyle(color: Palette.lavender, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(fmtTime(lesson.start).split(' ')[1],
                  style: const TextStyle(color: Palette.lavender, fontSize: 9)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lesson.title,
                  style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${lessonStudents[lesson.id]?.length ?? 0} students · ${lesson.room}',
                  style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ]),
          ),
          TagChip(lesson.mode == 'online' ? 'Online' : 'Offline',
              color: lesson.mode == 'online' ? Palette.mint : Palette.lavender),
        ]),
      ),
    );
  }
}

class _StudentPracticeRow extends StatelessWidget {
  const _StudentPracticeRow(this.name, this.minutes);
  final String name;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final onTrack = minutes >= 60;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text('$minutes / 120 min',
                style: const TextStyle(color: Palette.muted, fontSize: 11)),
            const SizedBox(width: 6),
            TagChip(onTrack ? 'On track' : 'Needs practice',
                color: onTrack ? Palette.mint : Palette.peach),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (minutes / 120).clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: Palette.cardHi,
              valueColor: AlwaysStoppedAnimation(onTrack ? Palette.mint : Palette.peach),
            ),
          ),
        ]),
      ),
    );
  }
}

// ================= ADMIN =================

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final today = allLessons
        .where((l) =>
            l.start.year == DateTime.now().year &&
            l.start.month == DateTime.now().month &&
            l.start.day == DateTime.now().day)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return _Page(
      children: [
        Row(children: [
          const IconChip(icon: Icons.dashboard_rounded, color: Palette.peach),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Good morning, Marcus.',
                  style: TextStyle(color: Palette.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              Text("This is what's happening at the academy today.",
                  style: const TextStyle(color: Palette.muted, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: StatTile(label: 'Total students', value: '78', accent: Palette.lavender)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'Teachers', value: '4', accent: Palette.mint)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: StatTile(label: 'Classes today', value: '${today.length}', accent: Palette.sky)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'Monthly revenue', value: r'$6,900', accent: Palette.peach)),
        ]),
        const SectionTitle("Today's schedule"),
        for (final l in today) _TeacherLessonRow(l),
        const SectionTitle('Pending fees'),
        AppCard(
          child: Row(children: [
            const IconChip(icon: Icons.receipt_rounded, color: Palette.peach),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(r'$240 in outstanding fees',
                    style: TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w700)),
                const Text('2 invoices awaiting payment', style: TextStyle(color: Palette.muted, fontSize: 11)),
              ]),
            ),
            TagChip('Action', color: Palette.peach, filled: true),
          ]),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class AdminFeesScreen extends StatefulWidget {
  const AdminFeesScreen({super.key});

  @override
  State<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends State<AdminFeesScreen> {
  late final List<Invoice> _invoices = [...invoices];

  @override
  Widget build(BuildContext context) {
    final pendingCount = _invoices.where((i) => i.status == 'pending').length;
    return _Page(
      children: [
        Row(children: [
          Expanded(child: StatTile(label: 'Collected', value: r'$240', accent: Palette.mint)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'Outstanding', value: r'$120', accent: Palette.peach)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: StatTile(label: 'Open invoices', value: '$pendingCount', accent: Palette.lavender)),
        ]),
        const SectionTitle('Invoices'),
        for (final inv in _invoices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(inv.description,
                        style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('Due ${fmtDate(inv.due)}',
                        style: const TextStyle(color: Palette.muted, fontSize: 11)),
                  ]),
                ),
                Text('\$${inv.amount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Palette.text, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (inv.status == 'pending')
                  GestureDetector(
                    onTap: () {
                      setState(() => inv.status = 'paid');
                      showToast(context, 'Payment recorded');
                    },
                    child: TagChip('Mark paid', color: Palette.mint, filled: true),
                  )
                else
                  TagChip('Paid', color: Palette.mint),
              ]),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ================= PARENT =================

class ParentHome extends StatelessWidget {
  const ParentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final week = weeklyMinutes.fold(0, (a, b) => a + b);
    final pct = ((week / 150 * 100).clamp(0, 100)).toDouble();
    return _Page(
      children: [
        Row(children: [
          const IconChip(icon: Icons.family_restroom_rounded, color: Palette.sky),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Hello, Rohan.',
                  style: TextStyle(color: Palette.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              const Text("Here's Aarav's progress.",
                  style: TextStyle(color: Palette.muted, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: StatTile(label: 'Practice this week', value: '$week min', accent: Palette.lavender)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'Skill score', value: '$overallSkill%', accent: Palette.mint)),
        ]),
        const SectionTitle('Child · Aarav Sharma'),
        AppCard(
          child: Row(children: [
            _Ring(progress: pct, label: '$pct%', sub: 'goal'),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Piano · Grade 3',
                    style: TextStyle(color: Palette.text, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Attendance 94% · 3-day streak',
                    style: TextStyle(color: Palette.muted, fontSize: 12)),
                const SizedBox(height: 8),
                const Text('Next class: Piano Fundamentals · Today 5:30 PM',
                    style: TextStyle(color: Palette.lavender, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SectionTitle('Recent lessons'),
        AppCard(
          child: Column(children: [
            _attendanceRow('Today · Piano Fundamentals', 'Present'),
            const Divider(color: Palette.border, height: 1),
            _attendanceRow('Tue · Piano Fundamentals', 'Late'),
            const Divider(color: Palette.border, height: 1),
            _attendanceRow('Last Mon · Piano Fundamentals', 'Present'),
          ]),
        ),
        const SectionTitle('Assignments due'),
        AppCard(
          child: Row(children: [
            const IconChip(icon: Icons.task_alt_rounded, color: Palette.peach),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('2 assignments in progress',
                    style: TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                const Text('1 due this week — Fur Elise Section A',
                    style: TextStyle(color: Palette.muted, fontSize: 11)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _attendanceRow(String label, String status) {
    final mint = status == 'Present';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: Palette.text, fontSize: 13))),
        TagChip(status, color: mint ? Palette.mint : Palette.peach),
      ]),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.label, required this.sub});
  final double progress;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72, height: 72,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 72, height: 72,
          child: CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 7,
            backgroundColor: Palette.cardHi,
            valueColor: const AlwaysStoppedAnimation(Palette.lavender),
          ),
        ),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label,
              style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(sub, style: const TextStyle(color: Palette.muted, fontSize: 7)),
        ]),
      ]),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline(this.message);
  final String message;
  @override
  Widget build(BuildContext context) =>
      Text(message, style: const TextStyle(color: Palette.muted, fontSize: 13));
}