import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

// ================= STUDENT HOME =================

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final lessons = myLessons('s1')..sort((a, b) => a.start.compareTo(b.start));
    final next = lessons.isEmpty ? null : lessons.first;
    final pending = myAssignments.where((a) => a.status == 'pending').toList();
    final weekMins = weeklyMinutes.fold(0, (a, b) => a + b);
    final pct = ((weekMins / 150 * 100).clamp(0, 100)).toDouble();

    return _Page(children: [
      // HEADER
      Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(gradient: Palette.gradientMusic, shape: BoxShape.circle),
          child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('STUDENT', style: TextStyle(color: Palette.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          Text('${_greeting()}, Aarav.', style: const TextStyle(color: Palette.text, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          Text('Ready for your next session?', style: const TextStyle(color: Palette.muted, fontSize: 13)),
        ])),
        IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none_rounded, color: Palette.muted), splashRadius: 22),
      ]),

      // HERO — Next Class
      if (next != null) ...[
        const SizedBox(height: 20),
        _Hero(next),
      ],

      // QUICK ACTIONS
      const SectionTitle('Quick actions'),
      Row(children: [
        _quickAction(Icons.timer_rounded, 'Practice', Palette.violet, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeScreen()))),
        const SizedBox(width: 10),
        _quickAction(Icons.calendar_month_rounded, 'Schedule', Palette.sky, () {}),
        const SizedBox(width: 10),
        _quickAction(Icons.task_alt_rounded, 'Assignments', Palette.peach, () {}),
        const SizedBox(width: 10),
        _quickAction(Icons.library_music_rounded, 'Library', Palette.mint, () {}),
      ]),

      // PRACTICE
      const SectionTitle('Practice this week'),
      AppCard(
        child: Column(children: [
          Row(children: [
            // Mini waveform
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$weekMins min', style: const TextStyle(color: Palette.text, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text('of 150 min weekly goal', style: const TextStyle(color: Palette.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: const [
                  Icon(Icons.local_fire_department_rounded, size: 14, color: Palette.peach),
                  SizedBox(width: 4),
                  Text('3-day streak', style: TextStyle(color: Palette.muted, fontSize: 12)),
                ]),
              ]),
            ),
            // Progress ring
            SizedBox(
              width: 64, height: 64,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: pct / 100, strokeWidth: 6, backgroundColor: Palette.cardHi, valueColor: const AlwaysStoppedAnimation(Palette.violet)),
                Text('${pct.round()}%', style: const TextStyle(color: Palette.violet, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          const WaveDecor(bars: 36, color: Color(0x338649F5)),
        ]),
      ),

      // ASSIGNMENTS
      if (pending.isNotEmpty) ...[
        const SectionTitle('Assignments due'),
        for (final a in pending)
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              IconChip(icon: Icons.task_alt_rounded, color: Palette.peach),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Due ${fmtDate(a.due)} · ${a.teacher}', style: const TextStyle(color: Palette.muted, fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Palette.peach.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                child: Text(a.difficulty, style: TextStyle(color: Palette.peach, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
      ],

      // PROGRESS
      const SectionTitle('Your progress'),
      Row(children: [
        _skillChip('Technique', 78),
        const SizedBox(width: 8),
        _skillChip('Rhythm', 65),
        const SizedBox(width: 8),
        _skillChip('Theory', 70),
        const SizedBox(width: 8),
        _skillChip('Performance', 74),
      ]),

      // ACTIVITY
      const SectionTitle('Recent activity'),
      for (final a in activity)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            IconChip(icon: Icons.music_note_rounded, size: 18, color: Palette.violet),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(a.detail, style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ])),
            Text(fmtDate(a.date), style: const TextStyle(color: Palette.muted, fontSize: 11)),
          ]),
        ),

      // ACHIEVEMENTS
      const SectionTitle('Achievements'),
      for (final ach in achievements)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            IconChip(
              icon: ach.icon == 'F' ? Icons.local_fire_department_rounded : ach.icon == 'C' ? Icons.schedule_rounded : Icons.emoji_events_rounded,
              color: Palette.peach,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ach.title, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(ach.detail, style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ])),
          ]),
        ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
      ),
    );
  }

  Widget _skillChip(String label, int score) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Palette.border.withValues(alpha: 0.5)),
        ),
        child: Column(children: [
          Text('$score', style: const TextStyle(color: Palette.violet, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Palette.muted, fontSize: 9), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ================= HERO =================

class _Hero extends StatelessWidget {
  const _Hero(this.lesson);
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final mins = lesson.start.difference(DateTime.now()).inMinutes;
    final countdown = mins <= 0 ? 'Now' : mins < 60 ? 'in $mins min' : 'in ${mins ~/ 60} hr ${mins % 60} min';
    final color = _hexColor(lesson.color);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: Palette.gradientHero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Palette.violetGlow, blurRadius: 32, offset: const Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
          child: Text('NEXT CLASS  ·  $countdown',
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(instrumentIcon(lesson.instrument), style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              Text('Today · ${fmtTime(lesson.start)} · ${lesson.minutes} min', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          )),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Icon(Icons.person_outline_rounded, size: 15, color: Colors.white54),
          const SizedBox(width: 6),
          Text('with ${lesson.teacher}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(lesson.mode == 'online' ? 'Online' : lesson.room, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        // Waveform decoration
        const Opacity(opacity: 0.15, child: WaveDecor(bars: 40, color: Colors.white, height: 24)),
      ]),
    );
  }
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

  static const _activities = ['Scales & Arpeggios', 'Sight Reading', 'Repertoire', 'Warm-up Exercises', 'Ear Training'];

  @override
  void dispose() { _tick?.cancel(); super.dispose(); }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}' : '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _toggle() {
    setState(() => _running = !_running);
    if (_running) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
    } else {
      _tick?.cancel();
      _tick = null;
    }
  }

  void _reset() { _tick?.cancel(); _tick = null; setState(() { _running = false; _seconds = 0; }); }

  void _finish() {
    if (_seconds == 0) return;
    _tick?.cancel(); _tick = null;
    final mins = (_seconds / 60).round().clamp(1, 999).toInt();
    setState(() { _running = false; _seconds = 0; });
    practiceSessions.insert(0, PracticeSession(id: 'p${DateTime.now().millisecondsSinceEpoch}', instrument: 'Piano', activity: _activity, minutes: mins, date: DateTime.now()));
    showToast(context, 'Logged $mins min of $_activity');
  }

  @override
  Widget build(BuildContext context) {
    final weekMins = weeklyMinutes.fold(0, (a, b) => a + b);
    final pct = ((weekMins / 150 * 100).clamp(0, 100)).toDouble();
    final maxDay = weeklyMinutes.fold(1, (a, b) => a > b ? a : b);
    final todayMins = practiceMinutesToday();

    return _Page(children: [
      Row(children: [
        Expanded(child: StatTile(label: 'Practice today', value: '$todayMins min', accent: Palette.violet)),
        const SizedBox(width: 10),
        Expanded(child: StatTile(label: 'Streak', value: '3 days', accent: Palette.peach)),
      ]),
      const SectionTitle('Start a session'),
      AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          // Activity picker
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              for (final a in _activities)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activity = a),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _activity == a ? Palette.violet : Palette.cardHi,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(a, style: TextStyle(color: _activity == a ? Colors.white : Palette.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ]),
          ),
          // Timer
          Text(_fmt(_seconds),
              style: TextStyle(color: Palette.text, fontSize: 52, fontWeight: FontWeight.w700, letterSpacing: -2, fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 8),
          // Waveform
          Opacity(opacity: _running ? 0.5 : 0.2, child: const WaveDecor(bars: 40, color: Palette.violet, height: 32)),
          const SizedBox(height: 20),
          // Controls
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: _reset,
              child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Palette.cardHi, shape: BoxShape.circle), child: const Icon(Icons.replay_rounded, color: Palette.muted)),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: _running ? Palette.peach : Palette.violet,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (_running ? Palette.peach : Palette.violet).withValues(alpha: 0.5), blurRadius: 20)],
                ),
                child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: _seconds == 0 ? null : _finish,
              child: Container(width: 48, height: 48, decoration: BoxDecoration(color: _seconds == 0 ? Palette.cardHi : Palette.mint, shape: BoxShape.circle),
                child: Icon(Icons.stop_rounded, color: _seconds == 0 ? Palette.muted : Colors.white, size: 20)),
            ),
          ]),
        ]),
      ),
      // Weekly chart
      const SectionTitle('This week'),
      AppCard(
        child: Column(children: [
          SizedBox(height: 100, child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [for (var i = 0; i < weeklyMinutes.length; i++)
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  height: 88 * weeklyMinutes[i] / maxDay,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Palette.violet, Palette.violet.withValues(alpha: 0.3)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(weekdayShort[i][0], style: const TextStyle(color: Palette.muted, fontSize: 10)),
              ])),
            ],
          )),
          const Divider(color: Palette.border, height: 24),
          Row(children: [
            SizedBox(
              width: 60, height: 60,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: pct / 100, strokeWidth: 6, backgroundColor: Palette.cardHi, valueColor: const AlwaysStoppedAnimation(Palette.violet)),
                Text('${pct.round()}%', style: const TextStyle(color: Palette.violet, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(width: 14),
            Text('$weekMins min of a 150 min weekly goal', style: const TextStyle(color: Palette.muted, fontSize: 12)),
          ]),
        ]),
      ),
      // Recent sessions
      const SectionTitle('Recent sessions'),
      for (final p in practiceSessions.take(6))
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            IconChip(icon: Icons.music_note_rounded, size: 18, color: Palette.mint),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.activity, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${fmtDate(p.date)} · ${p.instrument}', style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ])),
            Text('${p.minutes} min', style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      const SizedBox(height: 12),
    ]);
  }
}

// ================= PROGRESS =================

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(children: [
      const SectionTitle('Overall'),
      AppCard(
        child: Row(children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: overallSkill / 100, strokeWidth: 8, backgroundColor: Palette.cardHi, valueColor: const AlwaysStoppedAnimation(Palette.violet)),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$overallSkill%', style: const TextStyle(color: Palette.violet, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('overall', style: const TextStyle(color: Palette.muted, fontSize: 8)),
              ]),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Piano · Grade 3', style: TextStyle(color: Palette.text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('Up 4% this month', style: TextStyle(color: Palette.mint, fontSize: 12)),
            const SizedBox(height: 8),
            const WaveDecor(bars: 24, color: Palette.violet, height: 20),
          ])),
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
              Text(f.teacher, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Palette.violet.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                child: Text(f.category, style: TextStyle(color: Palette.violet, fontSize: 10, fontWeight: FontWeight.w600))),
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
            IconChip(icon: ach.icon == 'F' ? Icons.local_fire_department_rounded : ach.icon == 'C' ? Icons.schedule_rounded : Icons.emoji_events_rounded, color: Palette.peach),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ach.title, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(ach.detail, style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ])),
          ]),
        ),
      const SizedBox(height: 12),
    ]);
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
            Expanded(child: Text(skill.name, style: const TextStyle(color: Palette.muted, fontSize: 13))),
            Text('${skill.score}', style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(
            value: skill.score / 100, minHeight: 7, backgroundColor: Palette.cardHi,
            valueColor: const AlwaysStoppedAnimation(Palette.violet),
          )),
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
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: children));
  }
}