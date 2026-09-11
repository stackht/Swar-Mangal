import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'student_screens.dart';
import 'staff_screens.dart';

void main() => runApp(const SwarMangalApp());

enum Role { student, teacher, admin, parent }

const List<(Role, String, String, IconData, Color)> _roleEntries = [
  (Role.student, 'Student', 'Classes, practice & progress', Icons.school_rounded, Palette.violet),
  (Role.teacher, 'Teacher', 'Classes & student tracking', Icons.music_note_rounded, Palette.mint),
  (Role.admin, 'Admin', 'Academy operations & fees', Icons.dashboard_rounded, Palette.peach),
  (Role.parent, 'Parent', 'Monitor your child', Icons.family_restroom_rounded, Palette.sky),
];

class SwarMangalApp extends StatelessWidget {
  const SwarMangalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swar Mangal',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const LoginScreen(),
    );
  }
}

// ================= LOGIN =================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _entering = false;

  void _enter(Role role) {
    setState(() => _entering = true);
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Shell(role: role)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _entering
              ? const Center(child: CircularProgressIndicator(color: Palette.violet))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(gradient: Palette.gradientMusic, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Palette.violetGlow, blurRadius: 24, offset: const Offset(0, 8))]),
                            child: const Center(child: Text('S', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
                          )),
                          const SizedBox(height: 20),
                          Text('SWAR MANGAL', textAlign: TextAlign.center, style: TextStyle(color: Palette.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 3)),
                          const SizedBox(height: 6),
                          Text('Welcome back.', textAlign: TextAlign.center, style: TextStyle(color: Palette.text, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8)),
                          const SizedBox(height: 8),
                          Text('Your premium music academy companion.', textAlign: TextAlign.center, style: TextStyle(color: Palette.muted, fontSize: 14, height: 1.4)),
                          const SizedBox(height: 28),
                          Text('EXPLORE AS', style: TextStyle(color: Palette.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                          const SizedBox(height: 10),
                          for (final e in _roleEntries)
                            _roleCard(e.$1, e.$2, e.$3, e.$4, e.$5),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _roleCard(Role role, String label, String sub, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Palette.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _enter(role),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Palette.border.withValues(alpha: 0.5)),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Palette.text, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(sub, style: const TextStyle(color: Palette.muted, fontSize: 12)),
                ],
              )),
              const Icon(Icons.chevron_right_rounded, size: 14, color: Palette.muted),
            ]),
          ),
        ),
      ),
    );
  }
}

// ================= SHELL =================

class Shell extends StatefulWidget {
  const Shell({super.key, required this.role});
  final Role role;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  List<_TabDef> get _tabs => switch (widget.role) {
    Role.student => const [
      _TabDef(Icons.home_rounded, 'Home'),
      _TabDef(Icons.timer_rounded, 'Practice'),
      _TabDef(Icons.calendar_month_rounded, 'Schedule'),
      _TabDef(Icons.person_rounded, 'You'),
    ],
    Role.teacher => const [
      _TabDef(Icons.home_rounded, 'Home'),
      _TabDef(Icons.group_rounded, 'Students'),
      _TabDef(Icons.calendar_month_rounded, 'Schedule'),
      _TabDef(Icons.person_rounded, 'You'),
    ],
    Role.admin => const [
      _TabDef(Icons.home_rounded, 'Home'),
      _TabDef(Icons.receipt_rounded, 'Fees'),
      _TabDef(Icons.calendar_month_rounded, 'Schedule'),
      _TabDef(Icons.person_rounded, 'You'),
    ],
    Role.parent => const [
      _TabDef(Icons.home_rounded, 'Home'),
      _TabDef(Icons.trending_up_rounded, 'Progress'),
      _TabDef(Icons.calendar_month_rounded, 'Schedule'),
      _TabDef(Icons.person_rounded, 'You'),
    ],
  };

  List<Widget> _buildPages() => switch (widget.role) {
    Role.student => [const StudentHome(), const PracticeScreen(), ScheduleScreen(lessons: myLessons('s1')), AccountScreen(role: widget.role)],
    Role.teacher => [const TeacherHome(), const TeacherStudentsScreen(), ScheduleScreen(lessons: allLessons), AccountScreen(role: widget.role)],
    Role.admin => [const AdminHome(), const AdminFeesScreen(), ScheduleScreen(lessons: allLessons), AccountScreen(role: widget.role)],
    Role.parent => [const ParentHome(), const ProgressScreen(), ScheduleScreen(lessons: myLessons('s1')), AccountScreen(role: widget.role)],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bg,
      body: SafeArea(top: false, child: IndexedStack(index: _tab, children: _buildPages())),
      bottomNavigationBar: _FloatingPillNav(tabs: _tabs, current: _tab, onSelect: (i) => setState(() => _tab = i)),
    );
  }
}

class _TabDef {
  final IconData icon;
  final String label;
  const _TabDef(this.icon, this.label);
}

// =========== FLOATING PILL BOTTOM NAV ===========

class _FloatingPillNav extends StatelessWidget {
  const _FloatingPillNav({required this.tabs, required this.current, required this.onSelect});
  final List<_TabDef> tabs;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 8),
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Palette.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Palette.border.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: current == i ? Palette.violet : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tabs[i].icon, size: 21, color: current == i ? Colors.white : Palette.muted),
                      const SizedBox(height: 2),
                      Text(tabs[i].label,
                          style: TextStyle(fontSize: 10, fontWeight: current == i ? FontWeight.w700 : FontWeight.w500,
                              color: current == i ? Colors.white : Palette.muted)),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// =========== SHARED SCREENS ===========

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key, required this.lessons});
  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Lesson>>{};
    for (final l in lessons) {
      final key = '${l.start.year}-${l.start.month}-${l.start.day}';
      (grouped[key] ??= []).add(l);
    }
    final keys = grouped.keys.toList()..sort();
    return _Scaffold(
      title: 'Schedule',
      child: keys.isEmpty
          ? const Center(child: Text('No upcoming classes', style: TextStyle(color: Palette.muted)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [for (final key in keys) ...() {
                final day = grouped[key]!..sort((a, b) => a.start.compareTo(b.start));
                return [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Text('${fmtDate(day.first.start)}   ${weekdayShort[day.first.start.weekday - 1]}',
                        style: const TextStyle(color: Palette.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                  ),
                  ...day.map((l) => _LessonRow(lesson: l)),
                ];
              }()],
            ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(lesson.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => _showDetails(context, lesson),
        child: Row(children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(children: [
              Text((lesson.start.hour % 12 == 0 ? 12 : lesson.start.hour % 12).toString(),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              Text(lesson.start.hour >= 12 ? 'PM' : 'AM',
                  style: TextStyle(fontSize: 9, color: color)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.title, style: const TextStyle(color: Palette.text, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${lesson.teacher}  ·  ${lesson.instrument}', style: const TextStyle(color: Palette.muted, fontSize: 12)),
            ],
          )),
          Text('${lesson.minutes}m', style: const TextStyle(color: Palette.muted, fontSize: 12)),
        ]),
      ),
    );
  }

  void _showDetails(BuildContext context, Lesson l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Palette.border, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 16),
          Text(l.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Palette.text)),
          const SizedBox(height: 6),
          Text('${fmtDate(l.start)} · ${fmtTime(l.start)} – ${fmtTime(l.end)}', style: const TextStyle(color: Palette.muted)),
          const SizedBox(height: 14),
          Row(children: [
            _tag(l.mode == 'online' ? 'Online' : 'Offline', l.mode == 'online' ? Palette.mint : Palette.violet),
            const SizedBox(width: 8),
            Text('${l.teacher} · ${l.room}', style: const TextStyle(color: Palette.muted, fontSize: 13)),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _tag(String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

Color _hexColor(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

// =========== ACCOUNT + SHARED ===========

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.role});
  final Role role;

  @override
  Widget build(BuildContext context) {
    final me = role == Role.student || role == Role.parent ? 'Aarav Sharma' : role == Role.teacher ? 'Sarah Mitchell' : 'Marcus Reed';
    return _Scaffold(
      title: 'You',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          AppCard(child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(gradient: Palette.gradientMusic, shape: BoxShape.circle),
              child: Center(child: Text(me.split(' ').map((w) => w[0]).take(2).join(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(me, style: const TextStyle(color: Palette.text, fontSize: 15, fontWeight: FontWeight.w600)),
              Text(role.name.toUpperCase(), style: const TextStyle(color: Palette.muted, fontSize: 11, letterSpacing: 1)),
            ])),
          ])),
          const SizedBox(height: 16),
          _row(context, Icons.notifications_rounded, 'Notifications', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }),
          if (role == Role.student || role == Role.parent) _row(context, Icons.receipt_long_rounded, 'Payments', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentsScreen()));
          }),
          if (role == Role.student || role == Role.parent || role == Role.teacher) _row(context, Icons.trending_up_rounded, 'Progress', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
          }),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Palette.peach.withValues(alpha: 0.12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.logout_rounded, size: 18, color: Palette.peach),
                  SizedBox(width: 8),
                  Text('Sign out', style: TextStyle(color: Palette.peach, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(color: Palette.card, borderRadius: BorderRadius.circular(16), child: InkWell(
        borderRadius: BorderRadius.circular(16), onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Palette.border.withValues(alpha: 0.5))),
          child: Row(children: [
            Icon(icon, size: 20, color: Palette.violet),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: Palette.text, fontSize: 14))),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Palette.muted),
          ]),
        ),
      )),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final List<NotificationItem> _items = [...notifications];

  @override
  Widget build(BuildContext context) {
    return _Scaffold(
      title: 'Notifications',
      trailing: TextButton(onPressed: () => setState(() => _items.forEach((n) => n.read = true)),
          child: const Text('Mark all read', style: TextStyle(color: Palette.violet, fontSize: 12))),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [for (final n in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Palette.violet.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_none_rounded, color: Palette.violet, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(n.title, style: TextStyle(color: Palette.text, fontSize: 14, fontWeight: n.read ? FontWeight.w500 : FontWeight.w700))),
                  Text(fmtDate(n.date), style: const TextStyle(color: Palette.muted, fontSize: 11)),
                ]),
                const SizedBox(height: 3),
                Text(n.body, style: const TextStyle(color: Palette.muted, fontSize: 12)),
              ])),
            ])),
          ),
        ],
      ),
    );
  }
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late final List<Invoice> _invoices = [...invoices];

  @override
  Widget build(BuildContext context) {
    final pending = _invoices.where((i) => i.status == 'pending').fold(0.0, (s, i) => s + i.amount);
    return _Scaffold(
      title: 'Payments',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: StatTile(label: 'Outstanding', value: '\$${pending.toStringAsFixed(0)}', accent: Palette.peach)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'Paid to date', value: '\$${_invoices.where((i) => i.status == 'paid').fold(0.0, (s, i) => s + i.amount).toStringAsFixed(0)}', accent: Palette.mint)),
        ]),
        const SectionTitle('Invoices'),
        for (final inv in _invoices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(child: Row(children: [
              IconChip(icon: Icons.receipt_long_rounded, color: Palette.violet),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(inv.description, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Due ${fmtDate(inv.due)}', style: const TextStyle(color: Palette.muted, fontSize: 11)),
              ])),
              Text('\$${inv.amount.toStringAsFixed(0)}', style: const TextStyle(color: Palette.text, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              if (inv.status == 'pending')
                GestureDetector(
                  onTap: () { setState(() => inv.status = 'paid'); showToast(context, 'Payment recorded'); },
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Palette.mint, borderRadius: BorderRadius.circular(999)),
                    child: const Text('Pay now', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                )
              else
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Palette.mint.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                    child: Text('Paid', style: TextStyle(color: Palette.mint, fontSize: 11, fontWeight: FontWeight.w600))),
            ]), // Row
          ), // AppCard
        ), // Padding
      ]), // ListView children
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(children: [
            Expanded(child: Text(title, style: const TextStyle(color: Palette.text, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4))),
            if (trailing != null) trailing!,
          ]),
        ),
        Expanded(child: child),
      ]),
    );
  }
}