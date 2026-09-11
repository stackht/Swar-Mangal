import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

// ================= STUDENT HOME (Dashboard) =================

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final lessons = myLessons('s1')
      ..sort((a, b) => a.start.compareTo(b.start));
    final next = lessons.isEmpty ? null : lessons.first;
    final pending = myAssignments.where((a) => a.status == 'pending').toList();

    return _Page(
      children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Palette.lavender, Palette.mint]),
              shape: BoxShape.circle,
              border: Border.all(color: Palette.border),
            ),
            child: const Center(child: Text('A',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_greeting()}, Aarav.',
                  style: const TextStyle(
                      color: Palette.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              const Text('Ready for your next session?',
                  style: TextStyle(color: Palette.muted, fontSize: 13)),
            ]),
          ),
        ]),

        if (next != null) ...[
          const SizedBox(height: 20),
          _Hero(next),
        ],

        const SizedBox(height: 24),
        const SectionTitle('Quick actions'),
        _QuickActions(),

        const SizedBox(height: 8),
        const SectionTitle('Practice'),
        const _PracticeSummary(),

        const SectionTitle('Assignments'),
        if (pending.isEmpty)
          const _EmptyInline('All caught up — no pending assignments.')
        else
          for (final a in pending) _AssignmentRow(a),

        const SectionTitle('Recent activity'),
        for (final a in activity.take(4)) _ActivityRow(a),

        const SectionTitle('Achievements'),
        for (final ach in achievements) _AchievementRow(ach),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero(this.lesson);
  final Lesson lesson;
  static const _navyTop = Color(0xFF1B2533);
  static const _navyBottom = Color(0xFF101724);

  @override
  Widget build(BuildContext context) {
    final minutes = lesson.start.difference(DateTime.now()).inMinutes;
    final countdown = minutes <= 0
        ? 'Now'
        : minutes < 60
            ? 'in $minutes min'
            : 'in ${(minutes / 60).floor()} hr ${minutes % 60} min';
    final color = _hexColor(lesson.color);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [_navyTop, _navyBottom]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('NEXT CLASS  ·  $countdown',
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(instrumentIcon(lesson.instrument), style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lesson.title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
              Text('Today · ${fmtTime(lesson.start)} · ${lesson.minutes} min',
                  style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 15, color: Colors.white54),
          const SizedBox(width: 6),
          Text('with ${lesson.teacher}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(lesson.mode == 'online' ? 'Online' : lesson.room,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ]),
      ]),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.timer_rounded, 'Practice', 'Start a session', Palette.lavender),
      (Icons.calendar_month_rounded, 'Classes', 'Your schedule', Palette.sky),
      (Icons.task_alt_rounded, 'Assignments', '2 due this week', Palette.peach),
      (Icons.library_music_rounded, 'Library', 'Sheets & audio', Palette.mint),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.92,
      children: [
        for (final (icon, label, sub, accent) in items)
          AppCard(
            padding: const EdgeInsets.all(12),
            onTap: () => showToast(context, '$label opening soon'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 22, color: accent),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label,
                      style: const TextStyle(
                          color: Palette.text, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(sub,
                      style: const TextStyle(color: Palette.muted, fontSize: 10)),
                ]),
              ],
            ),
          ),
      ],
    );
  }
}

class _PracticeSummary extends StatelessWidget {
  const _PracticeSummary();

  @override
  Widget build(BuildContext context) {
    final week = weeklyMinutes.fold(0, (a, b) => a + b);
    final pct = ((week / 150 * 100).clamp(0, 100)).toDouble();
    return AppCard(
      child: Row(children: [
        _Ring(progress: pct, label: '${pct.round()}%', sub: 'of 150 min'),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$week min logged',
                style: const TextStyle(color: Palette.text, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${150 - week} min to reach your weekly goal',
                style: const TextStyle(color: Palette.muted, fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.local_fire_department_rounded, size: 16, color: Palette.peach),
              const SizedBox(width: 5),
              Text('3-day streak · ${practiceSessions.length} sessions',
                  style: const TextStyle(color: Palette.muted, fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            const _MiniWave(pct: 0.7),
          ]),
        ),
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
      width: 74, height: 74,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 74, height: 74,
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

class _MiniWave extends StatelessWidget {
  const _MiniWave({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 28; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.8),
                height: (10.0 + (i * 7) % 10),
                decoration: BoxDecoration(
                  color: Palette.lavender.withValues(alpha: 0.25 + (i % 4) * 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.item);
  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        const IconChip(icon: Icons.play_circle_outline_rounded, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title,
                style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(item.detail, style: const TextStyle(color: Palette.muted, fontSize: 11)),
          ]),
        ),
        Text(fmtDate(item.date), style: const TextStyle(color: Palette.muted, fontSize: 11)),
      ]),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow(this.ach);
  final Achievement ach;

  @override
  Widget build(BuildContext context) {
    final icon = ach.icon == 'F'
        ? Icons.local_fire_department_rounded
        : ach.icon == 'C'
            ? Icons.schedule_rounded
            : Icons.emoji_events_rounded;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        IconChip(icon: icon, color: Palette.peach),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ach.title,
                style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(ach.detail, style: const TextStyle(color: Palette.muted, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow(this.a);
  final Assignment a;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        const IconChip(icon: Icons.task_alt_rounded, color: Palette.peach),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.title,
                style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Due ${fmtDate(a.due)} · ${a.teacher}',
                style: const TextStyle(color: Palette.muted, fontSize: 11)),
          ]),
        ),
        TagChip(a.status == 'submitted' ? 'Submitted' : 'To do',
            color: a.status == 'submitted' ? Palette.mint : Palette.peach),
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

// ================= PRACTICE =================

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _seconds = 0;
  bool _running = false;
  String _activity = 'Scales & Arpeggios';
  Timer? _tick;

  static const _activities = [
    'Scales & Arpeggios',
    'Sight Reading',
    'Repertoire',
    'Warm-up Exercises',
    'Ear Training',
  ];

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  void _toggle() {
    setState(() => _running = !_running);
    if (_running) {
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
    } else {
      _tick?.cancel();
      _tick = null;
    }
  }

  void _reset() {
    _tick?.cancel();
    _tick = null;
    setState(() {
      _running = false;
      _seconds = 0;
    });
  }

  void _finish(BuildContext context) {
    if (_seconds == 0) return;
    _tick?.cancel();
    _tick = null;
    final mins = (_seconds / 60).round().clamp(1, 999).toInt();
    setState(() {
      _running = false;
      _seconds = 0;
    });
    practiceSessions.insert(
        0,
        PracticeSession(
            id: 'p-${DateTime.now().millisecondsSinceEpoch}',
            instrument: 'Piano',
            activity: _activity,
            minutes: mins,
            date: DateTime.now()));
    showToast(context, 'Logged $mins min of $_activity');
  }

  @override
  Widget build(BuildContext context) {
    final todayMins = practiceMinutesToday();
    final week = weeklyMinutes.fold(0, (a, b) => a + b);
    final pct = ((week / 150 * 100).clamp(0, 100)).toDouble();
    final maxDay = weeklyMinutes.fold(1, (a, b) => a > b ? a : b);

    return _Page(
      children: [
        Row(children: [
          Expanded(
            child: StatTile(label: 'Today', value: '$todayMins min', accent: Palette.lavender),
          ),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'Streak', value: '3 days', accent: Palette.peach)),
        ]),
        const SectionTitle('Start a session'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Palette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.border.withValues(alpha: 0.6)),
          ),
          child: Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                for (final a in _activities)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _activity = a),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _activity == a
                              ? Palette.lavender
                              : Palette.cardHi,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(a,
                            style: TextStyle(
                                color: _activity == a ? Colors.white : Palette.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ]),
            ),
            Text(_fmt(_seconds),
                style: const TextStyle(
                    color: Palette.text, fontSize: 46, fontWeight: FontWeight.w700, letterSpacing: -1,
                    fontFeatures: [FontFeature.tabularFigures()]),
                textScaler: const TextScaler.linear(0.95)),
            const SizedBox(height: 6),
            SizedBox(
              height: 26,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 24; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: _running ? 10.0 + (i * 5) % 16 : 6,
                    decoration: BoxDecoration(
                      color: _running
                          ? Palette.lavender.withValues(alpha: 0.5 + (i % 3) * 0.2)
                          : Palette.cardHi,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton.outlined(
                onPressed: _reset,
                icon: const Icon(Icons.replay_rounded, color: Palette.muted),
                style: IconButton.styleFrom(
                  backgroundColor: Palette.cardHi,
                  side: BorderSide.none,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: _running ? Palette.peach : Palette.lavender,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: (_running ? Palette.peach : Palette.lavender).withValues(alpha: 0.4), blurRadius: 18),
                    ],
                  ),
                  child: Icon(
                      _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 16),
              IconButton.outlined(
                onPressed: _seconds == 0 ? null : () => _finish(context),
                icon: const Icon(Icons.stop_rounded, color: Palette.muted),
                style: IconButton.styleFrom(
                  backgroundColor: Palette.cardHi,
                  side: BorderSide.none,
                  disabledBackgroundColor: Palette.cardHi.withValues(alpha: 0.4),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 4),
        const SectionTitle('This week'),
        AppCard(
          child: Column(children: [
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < weeklyMinutes.length; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 88 * weeklyMinutes[i] / maxDay,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: [Palette.lavender, Palette.lavender.withValues(alpha: 0.3)]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(weekdayShort[i][0],
                              style: const TextStyle(color: Palette.muted, fontSize: 10)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: Palette.border, height: 24),
            Row(children: [
              _Ring(progress: pct, label: '$pct%', sub: 'goal'),
              const SizedBox(width: 16),
              Expanded(
                child: Text('$week min of a 150 min weekly goal',
                    style: const TextStyle(color: Palette.muted, fontSize: 12)),
              ),
            ]),
          ]),
        ),
        const SectionTitle('Recent sessions'),
        for (final p in practiceSessions.take(6))
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const IconChip(icon: Icons.music_note_rounded, size: 18, color: Palette.mint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.activity,
                      style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${fmtDate(p.date)} · ${p.instrument}',
                      style: const TextStyle(color: Palette.muted, fontSize: 11)),
                ]),
              ),
              Text('${p.minutes} min',
                  style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ================= PROGRESS =================

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        const SectionTitle('Overall'),
        AppCard(
          child: Row(children: [
            _Ring(progress: overallSkill / 100, label: '$overallSkill%', sub: 'overall'),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Piano · Grade 3',
                    style: TextStyle(color: Palette.text, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('Skill score trend is up 4% this month.',
                    style: TextStyle(color: Palette.muted, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: const [
                  Icon(Icons.trending_up_rounded, size: 16, color: Palette.mint),
                  SizedBox(width: 4),
                  Text('Great consistency — keep it up.',
                      style: TextStyle(color: Palette.mint, fontSize: 12)),
                ]),
              ]),
            ),
          ]),
        ),
        const SectionTitle('Skill areas'),
        for (final s in skills) _SkillBar(s),
        const SectionTitle('Teacher feedback'),
        for (final f in feedbackList)
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(f.teacher,
                    style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                TagChip(f.category, color: Palette.lavender),
              ]),
              const SizedBox(height: 6),
              Text(f.body, style: const TextStyle(color: Palette.muted, fontSize: 12, height: 1.4)),
            ]),
          ),
        const SectionTitle('Achievements'),
        for (final ach in achievements)
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              IconChip(
                  icon: ach.icon == 'F'
                      ? Icons.local_fire_department_rounded
                      : ach.icon == 'C'
                          ? Icons.schedule_rounded
                          : Icons.emoji_events_rounded,
                  color: Palette.peach),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ach.title,
                      style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(ach.detail, style: const TextStyle(color: Palette.muted, fontSize: 11)),
                ]),
              ),
            ]),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar(this.skill);
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Text(skill.name,
                  style: const TextStyle(color: Palette.muted, fontSize: 13)),
            ),
            Text('${skill.score}',
                style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: skill.score / 100,
              minHeight: 7,
              backgroundColor: Palette.cardHi,
              valueColor: const AlwaysStoppedAnimation(Palette.lavender),
            ),
          ),
        ]),
      ),
    );
  }
}

Color _hexColor(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

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