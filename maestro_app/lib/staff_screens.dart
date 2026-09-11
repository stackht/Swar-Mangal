import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'main.dart' show Role;

// =========== SHARED ===========

class _Page extends StatelessWidget {
  const _Page({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: children));
  }
}

// ================= TEACHER =================

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final today = allLessons.where((l) =>
      l.start.year == DateTime.now().year && l.start.month == DateTime.now().month && l.start.day == DateTime.now().day
    ).toList()..sort((a, b) => a.start.compareTo(b.start));

    return _Page(children: [
      Row(children: [
        IconChip(icon: Icons.music_note_rounded, color: Palette.mint),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_greeting()}, Sarah.', style: const TextStyle(color: Palette.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          Text('${today.length} classes today', style: const TextStyle(color: Palette.muted, fontSize: 13)),
        ])),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: StatTile(label: 'Classes today', value: '${today.length}', accent: Palette.violet)),
        const SizedBox(width: 10),
        Expanded(child: StatTile(label: 'Students', value: '${teacherStudentNames.length}', accent: Palette.mint)),
      ]),
      const SectionTitle("Today's teaching"),
      if (today.isEmpty)
        AppCard(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.music_note_rounded, color: Palette.muted, size: 20),
          SizedBox(width: 8),
          Text('No classes today', style: TextStyle(color: Palette.muted)),
        ]))
      else
        for (final l in today)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(child: Row(children: [
              Container(
                width: 48, padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Palette.violet.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
                child: Column(children: [
                  Text(fmtTime(l.start).split(' ')[0], style: const TextStyle(color: Palette.violet, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(fmtTime(l.start).split(' ')[1], style: const TextStyle(color: Palette.violet, fontSize: 9)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.title, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${(lessonStudents[l.id] ?? []).length} students · ${l.room}', style: const TextStyle(color: Palette.muted, fontSize: 11)),
              ])),
              Opacity(opacity: 0.5, child: SizedBox(width: 48, child: WaveDecor(bars: 10, color: Palette.violet, height: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: l.mode == 'online' ? Palette.mint.withValues(alpha: 0.15) : Palette.violet.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                child: Text(l.mode, style: TextStyle(color: l.mode == 'online' ? Palette.mint : Palette.violet, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ]),  // closes Row
          ),     // closes AppCard
        ),       // closes Padding
      const SectionTitle('Students needing attention'),
      for (final name in teacherStudentNames)
        _StudentAttention(name, teacherPractice[name] ?? 0),
      const SectionTitle('To review'),
      AppCard(child: Row(children: [
        const IconChip(icon: Icons.task_alt_rounded, color: Palette.peach),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('2 assignments awaiting review', style: TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
          Text('C Major Scales · Fur Elise', style: TextStyle(color: Palette.muted, fontSize: 11)),
        ])),
      ])),
    ]);
  }
}

class _StudentAttention extends StatelessWidget {
  const _StudentAttention(this.name, this.minutes);
  final String name;
  final int minutes;
  @override
  Widget build(BuildContext context) {
    final onTrack = minutes >= 60;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        CircleAvatar(radius: 18, backgroundColor: Palette.cardHi, child: Text(name[0], style: const TextStyle(color: Palette.muted, fontSize: 13))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
          Text('$minutes / 120 min this week', style: const TextStyle(color: Palette.muted, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: onTrack ? Palette.mint.withValues(alpha: 0.15) : Palette.peach.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(onTrack ? 'On track' : 'Needs practice', style: TextStyle(color: onTrack ? Palette.mint : Palette.peach, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ================= ADMIN =================

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final today = allLessons.where((l) =>
      l.start.year == DateTime.now().year && l.start.month == DateTime.now().month && l.start.day == DateTime.now().day
    ).toList();
    return _Page(children: [
      Row(children: [
        IconChip(icon: Icons.dashboard_rounded, color: Palette.peach),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Good morning, Marcus.', style: TextStyle(color: Palette.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          Text('Academy overview', style: TextStyle(color: Palette.muted, fontSize: 13)),
        ])),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: StatTile(label: 'Students', value: '${students.length}', accent: Palette.violet)),
        const SizedBox(width: 10),
        Expanded(child: StatTile(label: 'Teachers', value: '${teacherStudentNames.length}', accent: Palette.mint)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: StatTile(label: 'Classes today', value: '${today.length}', accent: Palette.sky)),
        const SizedBox(width: 10),
        Expanded(child: StatTile(label: 'Revenue', value: '\$6,900', accent: Palette.peach)),
      ]),
      const SectionTitle('Today\'s schedule'),
      for (final l in today)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Text(fmtTime(l.start).split(' ')[0], style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.title, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${l.teacher} · ${(lessonStudents[l.id] ?? []).length} students', style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Palette.violet.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
              child: Text(l.mode, style: TextStyle(color: Palette.violet, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      if (today.isEmpty) const Center(child: Text('No classes today', style: TextStyle(color: Palette.muted))),
      const SectionTitle('Quick actions'),
      Row(children: [
        _action(Icons.person_add_rounded, 'Add Student', Palette.violet),
        const SizedBox(width: 10),
        _action(Icons.group_add_rounded, 'Add Teacher', Palette.mint),
        const SizedBox(width: 10),
        _action(Icons.music_note_rounded, 'New Course', Palette.peach),
        const SizedBox(width: 10),
        _action(Icons.receipt_rounded, 'Manage Fees', Palette.sky),
      ]),
    ]);
  }

  Widget _action(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.border.withValues(alpha: 0.5)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Palette.text, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class TeacherStudentsScreen extends StatelessWidget {
  const TeacherStudentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _Page(children: [
      const Text('My Students', style: TextStyle(color: Palette.text, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
      const SizedBox(height: 16),
      for (final name in teacherStudentNames)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: Palette.cardHi, child: Text(name[0], style: const TextStyle(color: Palette.muted, fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Palette.text, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('${teacherPractice[name] ?? 0} min / 120 min this week', style: const TextStyle(color: Palette.muted, fontSize: 12)),
            ])),
            Text('${teacherPractice[name] ?? 0} min', style: const TextStyle(color: Palette.violet, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
    ]);
  }
}

// ProgressScreen lives in student_screens.dart; parent reuses it.

// ================= ADMIN FEES =================

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
    return _Page(children: [
      Row(children: [
        Expanded(child: StatTile(label: 'Collected', value: '\$240', accent: Palette.mint)),
        const SizedBox(width: 10),
        Expanded(child: StatTile(label: 'Outstanding', value: '\$120', accent: Palette.peach)),
      ]),
      const SectionTitle('Invoices'),
      for (final inv in _invoices)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(inv.description, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Due ${fmtDate(inv.due)}', style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ])),
            Text('\$${inv.amount.toStringAsFixed(0)}', style: const TextStyle(color: Palette.text, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (inv.status == 'pending')
              GestureDetector(
                onTap: () { setState(() => inv.status = 'paid'); showToast(context, 'Payment recorded'); },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Palette.mint, borderRadius: BorderRadius.circular(999)),
                    child: const Text('Mark paid', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
              )
            else
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Palette.mint.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                  child: Text('Paid', style: TextStyle(color: Palette.mint, fontSize: 11, fontWeight: FontWeight.w600))),
          ]),
        ),
    ]);
  }
}

// ================= PARENT =================

class ParentHome extends StatelessWidget {
  const ParentHome({super.key});
  @override
  Widget build(BuildContext context) {
    final weekMins = weeklyMinutes.fold(0, (a, b) => a + b);
    final pct = ((weekMins / 150 * 100).clamp(0, 100)).toDouble();
    return _Page(children: [
      Row(children: [
        IconChip(icon: Icons.family_restroom_rounded, color: Palette.sky),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Hello, Rohan.', style: TextStyle(color: Palette.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          Text('Monitoring Aarav\'s musical journey', style: TextStyle(color: Palette.muted, fontSize: 13)),
        ])),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: StatTile(label: 'Practice this week', value: '$weekMins min', accent: Palette.violet)),
        const SizedBox(width: 10),
        Expanded(child: StatTile(label: 'Skill score', value: '$overallSkill%', accent: Palette.mint)),
      ]),
      const SectionTitle('Instrument progress'),
      AppCard(
        child: Row(children: [
          SizedBox(
            width: 68, height: 68,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: pct / 100, strokeWidth: 6, backgroundColor: Palette.cardHi, valueColor: const AlwaysStoppedAnimation(Palette.violet)),
              Text('${pct.round()}%', style: const TextStyle(color: Palette.violet, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Piano · Grade 3', style: TextStyle(color: Palette.text, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('Attendance 94% · 3-day streak', style: TextStyle(color: Palette.muted, fontSize: 12)),
            const SizedBox(height: 8),
            Text('Next: Piano Fundamentals · ${fmtTime(allLessons.first.start)}', style: const TextStyle(color: Palette.violet, fontSize: 12)),
          ])),
        ]),
      ),
      const SectionTitle('Upcoming'),
      for (final l in allLessons.where((l) => (lessonStudents[l.id] ?? []).contains('s1')).take(2))
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Text(fmtTime(l.start).split(' ')[0], style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.title, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(l.teacher, style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ])),
            Text('${l.minutes}m', style: const TextStyle(color: Palette.muted, fontSize: 12)),
          ]),
        ),
    ]);
  }
}