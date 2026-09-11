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
    final todayMins = practiceMinutesToday();

    return _Page(children: [
      _buildHeader(context),
      if (next != null) ...[
        const SizedBox(height: 20),
        _Hero(lesson: next),
      ],
      const SizedBox(height: 20),
      _buildPills(context),
      const SizedBox(height: 24),
      _buildQuickActions(context),
      const SizedBox(height: 26),
      _TodayBand(todayMins: todayMins, pendingCount: pending.length, pct: pct),
      const SizedBox(height: 26),
      _PracticeSignature(weekMins: weekMins, pct: pct),
      const SizedBox(height: 26),
      _ProgressSection(),
      const SizedBox(height: 26),
      _RecentPractice(lessons: practiceSessions.take(4).toList()),
      const SizedBox(height: 26),
      const _Milestones(),
      const SizedBox(height: 12),
    ]);
  }

  Widget _buildHeader(BuildContext context) {
    return Row(children: [
      Stack(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Palette.violet, Palette.violetSoft]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Palette.violetGlow, blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17))),
        ),
        Positioned(right: 0, bottom: 0, child: Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: Palette.lime, shape: BoxShape.circle, border: Border.all(color: Palette.bg, width: 2)),
        )),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PIANO · GRADE 3', style: TextStyle(color: Palette.muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
        const SizedBox(height: 2),
        Text('${_greeting()}, Aarav.', style: const TextStyle(color: Palette.text, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        Text('Your next session is in reach.', style: const TextStyle(color: Palette.muted, fontSize: 12)),
      ])),
      SizedBox(
        width: 42, height: 42,
        child: IconButton(
          onPressed: () {},
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.notifications_none_rounded, color: Palette.muted, size: 22),
        ),
      ),
    ]);
  }

  Widget _buildPills(BuildContext context) {
    final pills = <(String, Widget, VoidCallback)>[
      ('ALL', const SizedBox.shrink(), () {}),
      ('PRACTICE', const SizedBox.shrink(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeScreen()))),
      ('LESSONS', const SizedBox.shrink(), () {}),
      ('ASSIGNMENTS', const SizedBox.shrink(), () {}),
      ('LIBRARY', const SizedBox.shrink(), () {}),
      ('PROGRESS', const SizedBox.shrink(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressScreen()))),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pills.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _Pill(label: pills[i].$1, onTap: pills[i].$3, active: i == 0),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = <(IconData, String, String, Color, VoidCallback)>[
      (Icons.timer_rounded, 'Practice', 'Start a session', Palette.violet, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeScreen()))),
      (Icons.calendar_month_rounded, 'Schedule', 'Your timetable', Palette.sky, () {}),
      (Icons.task_alt_rounded, 'Assign', 'Tasks to do', Palette.peach, () {}),
      (Icons.library_music_rounded, 'Library', 'Sheets & audio', Palette.mint, () {}),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _QuickAction(actions[i].$2, actions[i].$3, actions[i].$1, actions[i].$4, actions[i].$5)),
          if (i < actions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

// ================= HEADER PIECE: HERO =================

class _Hero extends StatefulWidget {
  const _Hero({required this.lesson});
  final Lesson lesson;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
  late final Animation<double> _pulse = CurvedAnimation(parent: _wave, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations && !_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  String _countdown() {
    final mins = widget.lesson.start.difference(DateTime.now()).inMinutes;
    if (mins <= 0) return 'Now';
    if (mins < 60) return 'in $mins min';
    return 'in ${mins ~/ 60} hr ${mins % 60} min';
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final color = _hexColor(l.color);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: Palette.gradientHero,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: Palette.violetGlow, blurRadius: 36, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Countdown pill with live dot
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            FadeTransition(
              opacity: _pulse,
              child: Container(width: 7, height: 7, decoration: BoxDecoration(color: Palette.lime, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 8),
            Text('NEXT CLASS  ·  ${_countdown()}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8C4BEF), Color(0xFFD946EF)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Center(child: Text(instrumentIcon(l.instrument), style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CONTINUE YOUR JOURNEY', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
            const SizedBox(height: 3),
            Text(l.title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text('Today · ${fmtTime(l.start)} · ${l.minutes} min', style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 15, color: Colors.white54),
          const SizedBox(width: 6),
          Text('with ${l.teacher}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(l.mode == 'online' ? 'Online' : l.room, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        // Waveform signature (animated)
        _HeroWave(progress: _pulse),
      ]),
    );
  }
}

class _HeroWave extends StatelessWidget {
  const _HeroWave({required this.progress});
  final Animation<double> progress;
  final int _bars = 42;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_bars, (i) {
          final base = 8 + (i * 7) % 18;
          return Expanded(
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                final wave = i % 2 == 0 ? progress.value : 1 - progress.value;
                final h = base + (wave * 10);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0.7),
                  height: h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18 + (i % 4) * 0.05),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

// ================= PILL =================

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.active = false});
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Palette.violet : Palette.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? Colors.transparent : Palette.border.withValues(alpha: 0.5)),
          boxShadow: active ? [BoxShadow(color: Palette.violetGlow, blurRadius: 16, offset: const Offset(0, 6))] : null,
        ),
        child: Text(label,
            style: TextStyle(color: active ? Colors.white : Palette.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ),
    );
  }
}

// ================= QUICK ACTION =================

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.label, this.sub, this.icon, this.color, this.onTap);
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.border.withValues(alpha: 0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(sub, style: const TextStyle(color: Palette.muted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ================= TODAY BAND =================

class _TodayBand extends StatelessWidget {
  const _TodayBand({required this.todayMins, required this.pendingCount, required this.pct});
  final int todayMins;
  final int pendingCount;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Row(children: [
          _bandItem(Icons.schedule_rounded, 'Practice today', '$todayMins min', Palette.sky),
          _bandSeparator(),
          _bandItem(Icons.local_fire_department_rounded, 'Streak', '3 days', Palette.peach),
          _bandSeparator(),
          _bandItem(Icons.task_alt_rounded, 'Assignments', '$pendingCount', Palette.violet),
          _bandSeparator(),
          _bandItem(Icons.trending_up_rounded, 'Progress', '${pct.round()}%', Palette.mint),
        ]),
        const Divider(color: Palette.border, height: 1, thickness: 1),
        const SizedBox(
          height: 18,
          child: Opacity(opacity: 0.35, child: WaveDecor(bars: 48, color: Palette.violet)),
        ),
      ]),
    );
  }

  Widget _bandSeparator() => Container(width: 1, height: 34, color: Palette.border.withValues(alpha: 0.6));

  Widget _bandItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Palette.text, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Palette.muted, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ================= PRACTICE SIGNATURE =================

class _PracticeSignature extends StatelessWidget {
  const _PracticeSignature({required this.weekMins, required this.pct});
  final int weekMins;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        Row(children: [
          SizedBox(
            width: 76, height: 76,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 76, height: 76,
                child: CircularProgressIndicator(
                  value: pct / 100, strokeWidth: 7, backgroundColor: Palette.cardHi,
                  valueColor: const AlwaysStoppedAnimation(Palette.violet),
                ),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${pct.round()}%', style: const TextStyle(color: Palette.violet, fontSize: 16, fontWeight: FontWeight.w700)),
                Text('goal', style: const TextStyle(color: Palette.muted, fontSize: 8)),
              ]),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$weekMins min', style: const TextStyle(color: Palette.text, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            Text('practiced this week', style: const TextStyle(color: Palette.muted, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: const [
              Icon(Icons.local_fire_department_rounded, size: 14, color: Palette.peach),
              SizedBox(width: 4),
              Text('3-day streak · 5 sessions', style: TextStyle(color: Palette.muted, fontSize: 11)),
            ]),
          ])),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeScreen())),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8C4BEF), Color(0xFFC026D3)]),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [BoxShadow(color: Palette.violetGlow, blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text('Start Practice', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ================= PROGRESS =================

class _ProgressSection extends StatelessWidget {
  const _ProgressSection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Your progress'),
      AppCard(
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Piano · Grade 3', style: TextStyle(color: Palette.text, fontSize: 15, fontWeight: FontWeight.w700)),
              const Text('Improving steadily', style: TextStyle(color: Palette.muted, fontSize: 12)),
            ])),
            Text('$overallSkill%', style: const TextStyle(color: Palette.violet, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          ]),
          const SizedBox(height: 14),
          for (final s in skills.take(6)) ...[
            Row(children: [
              SizedBox(width: 96, child: Text(s.name, style: const TextStyle(color: Palette.muted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 10),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(
                value: s.score / 100, minHeight: 7, backgroundColor: Palette.cardHi,
                valueColor: const AlwaysStoppedAnimation(Palette.violet),
              ))),
              const SizedBox(width: 10),
              SizedBox(width: 28, child: Text('${s.score}', style: const TextStyle(color: Palette.muted, fontSize: 11), textAlign: TextAlign.right)),
            ]),
            if (s != skills.take(6).last) const SizedBox(height: 10),
          ],
        ]),
      ),
    ]);
  }
}

// ================= RECENT PRACTICE =================

class _RecentPractice extends StatelessWidget {
  const _RecentPractice({required this.lessons});
  final List<PracticeSession> lessons;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Recent practice'),
      for (final p in lessons)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Opacity(opacity: 0.6, child: SizedBox(width: 52, child: WaveDecor(bars: 12, color: Palette.violet, height: 20))),
            const SizedBox(width: 4),
            Container(width: 1, height: 26, color: Palette.border.withValues(alpha: 0.6)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.activity, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${fmtDate(p.date)} · ${p.instrument}', style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ])),
            Text('${p.minutes} min', style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
    ]);
  }
}

// ================= MILESTONES =================

class _Milestones extends StatelessWidget {
  const _Milestones();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Milestones'),
      for (var i = 0; i < achievements.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8C4BEF), Color(0xFFD946EF)]),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  achievements[i].icon == 'F' ? Icons.local_fire_department_rounded
                    : achievements[i].icon == 'C' ? Icons.schedule_rounded : Icons.auto_awesome_rounded,
                  color: Colors.white, size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(achievements[i].title, style: const TextStyle(color: Palette.text, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(achievements[i].detail, style: const TextStyle(color: Palette.muted, fontSize: 11)),
              ])),
              Text(i == 0 ? 'Active' : 'Earned', style: const TextStyle(color: Palette.muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            ]),
          ),
        ),
    ]);
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
                      decoration: BoxDecoration(color: _activity == a ? Palette.violet : Palette.cardHi, borderRadius: BorderRadius.circular(999)),
                      child: Text(a, style: TextStyle(color: _activity == a ? Colors.white : Palette.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ]),
          ),
          Text(_fmt(_seconds), style: TextStyle(color: Palette.text, fontSize: 52, fontWeight: FontWeight.w700, letterSpacing: -2)),
          const SizedBox(height: 8),
          Opacity(opacity: _running ? 0.5 : 0.2, child: const WaveDecor(bars: 40, color: Palette.violet, height: 32)),
          const SizedBox(height: 20),
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
                decoration: BoxDecoration(color: _running ? Palette.peach : Palette.violet, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (_running ? Palette.peach : Palette.violet).withValues(alpha: 0.5), blurRadius: 20)]),
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
      const SectionTitle('This week'),
      AppCard(
        child: Column(children: [
          SizedBox(height: 100, child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [for (var i = 0; i < weeklyMinutes.length; i++)
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  height: 78 * weeklyMinutes[i] / maxDay,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Palette.violet, Palette.violet.withValues(alpha: 0.3)]), borderRadius: BorderRadius.circular(8)),
                ),
                const SizedBox(height: 6),
                Text(weekdayShort[i][0], style: const TextStyle(color: Palette.muted, fontSize: 10)),
              ])),
            ],
          )),
          const Divider(color: Palette.border, height: 24),
          Row(children: [
            SizedBox(width: 60, height: 60, child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: pct / 100, strokeWidth: 6, backgroundColor: Palette.cardHi, valueColor: const AlwaysStoppedAnimation(Palette.violet)),
              Text('${pct.round()}%', style: const TextStyle(color: Palette.violet, fontSize: 11, fontWeight: FontWeight.w700)),
            ])),
            const SizedBox(width: 14),
            Text('$weekMins min of a 150 min weekly goal', style: const TextStyle(color: Palette.muted, fontSize: 12)),
          ]),
        ]),
      ),
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
          SizedBox(width: 80, height: 80, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: overallSkill / 100, strokeWidth: 8, backgroundColor: Palette.cardHi, valueColor: const AlwaysStoppedAnimation(Palette.violet)),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$overallSkill%', style: const TextStyle(color: Palette.violet, fontSize: 18, fontWeight: FontWeight.w700)),
              Text('overall', style: const TextStyle(color: Palette.muted, fontSize: 8)),
            ]),
          ])),
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
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: children));
  }
}