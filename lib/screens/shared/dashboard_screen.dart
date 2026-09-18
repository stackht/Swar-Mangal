import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/sync_manager.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/atoms.dart';
import 'fee_bucket_screen.dart';
import 'inquiries_screen.dart';
import 'todays_classes_screen.dart';
import '../shell/shell_nav.dart';

/// Founder home: today's money + recent receipts + fee buckets.
class FounderDashboard extends StatelessWidget {
  const FounderDashboard({super.key});

  Future<({DashboardMetrics metrics, DueReminders dues, List<Student>? extra})>
      _load(AuthProvider auth) async {
    final s = auth.service!;
    final results = await Future.wait([
      s.dashboard('CONSOLIDATED'),
      s.dueReminders('ALL'),
    ]);
    return (
      metrics: results[0] as DashboardMetrics,
      dues: results[1] as DueReminders,
      extra: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return _Body(auth: auth, load: () => _load(auth));
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.auth, required this.load});
  final AuthProvider auth;
  final Future<({DashboardMetrics metrics, DueReminders dues, List<Student>? extra})> Function() load;
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SyncAware {
  @override
  Set<String> get syncEntities => const {'dashboard', 'receipts', 'students'};

  @override
  Future<void> reloadFromSync() => _fetch();

  DashboardMetrics? _metrics;
  DueReminders? _dues;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await widget.load();
      if (!mounted) return;
      setState(() {
        _metrics = r.metrics;
        _dues = r.dues;
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy && _metrics == null) {
      return const SkeletonList(rows: 8);
    }
    if (_error != null && _metrics == null && _dues == null) {
      return ErrorView(_error!, onRetry: _fetch);
    }
    final m = _metrics;
    final d = _dues;
    final refresh = Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(AppSpace.s3),
            child: ErrorView(_error!, onRetry: _fetch, compact: true),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.s4),
            children: [
              PageHero(eyebrow: 'Today', headline: 'Good ${_greeting()}.'),
              const SizedBox(height: AppSpace.s4),
              if (m != null) ...[
                if (m.approvalsCount > 0) _approvalsBanner(m.approvalsCount),
                _moneyRow(m),
                const SizedBox(height: AppSpace.s3),
                // Rows size to their content. A fixed aspect-ratio grid clipped
                // the figures on phones (and worse with a larger system font).
                _tilePair(
                  StatTile(
                    label: 'Due Today',
                    value: '${m.dueTodayCount}',
                    icon: Icons.today,
                    accent: AppColors.adaptive(context, AppColors.warnFg),
                    onTap: () => _openFeeBucket('DUE_TODAY', 'Fees Due Today'),
                  ),
                  StatTile(
                    label: 'Overdue',
                    value: '${m.overdueCount}',
                    icon: Icons.flag_outlined,
                    accent: AppColors.adaptive(context, AppColors.blockFg),
                    onTap: () => _openFeeBucket('OVERDUE', 'Fees Overdue'),
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                _tilePair(
                  StatTile(label: 'Terms Pending', value: '${m.termsPendingCount}', icon: Icons.assignment_outlined),
                  StatTile(label: 'This Month', value: '${m.monthCount} rct', icon: Icons.receipt_outlined, accent: AppColors.adaptive(context, AppColors.focus)),
                ),
                const SectionTitle("Today's to-do"),
                _todoGrid(m.cards),
                const SectionTitle("Today's lectures"),
                _lecturesCard(m.overview.todaysLectures),
                const SectionTitle('Attendance'),
                _attendanceCard(m.overview.attendance),
                const SectionTitle('Enquiries'),
                _enquiriesCard(m.overview.enquiries),
                const SectionTitle('Teacher attendance'),
                _teacherAttendanceCard(m.overview.teacherAttendance),
                const SectionTitle('Recent receipts'),
                for (final r in m.recent.take(6)) _receiptTile(r),
                if (m.recent.isEmpty) const EmptyState('No receipt activity yet'),
              ],
              if (d != null && d.count > 0) ...[
                const SectionTitle('Fee buckets'),
                _bucket('Due today', d.dueToday, AppColors.adaptive(context, AppColors.warnFg)),
                _bucket('Overdue', d.overdue, AppColors.adaptive(context, AppColors.blockFg)),
                _bucket('Due soon', d.dueSoon, AppColors.adaptive(context, AppColors.infoFg)),
              ],
            ],
          ),
        ),
      ],
    );
    return RefreshScaffold(onRefresh: _fetch, child: refresh);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  void _openFeeBucket(String bucket, String title) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FeeBucketScreen(bucket: bucket, title: title, staff: false),
    ));
  }

  Widget _approvalsBanner(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s3),
      child: Card(
        color: AppColors.adaptive(context, AppColors.warnBg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => ShellNavigator.of(context).go('approvals'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Row(children: [
              Icon(Icons.fact_check_outlined, color: AppColors.adaptive(context, AppColors.warnFg)),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Text('$count awaiting your approval',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.adaptive(context, AppColors.warnFg), fontSize: 14)),
              ),
              Icon(Icons.chevron_right, color: AppColors.adaptive(context, AppColors.warnFg)),
            ]),
          ),
        ),
      ),
    );
  }

  static const _feeBucketByCardKey = {
    'FEES_OVERDUE': 'OVERDUE',
    'FEES_DUE_TODAY': 'DUE_TODAY',
    'FEES_DUE_SOON': 'DUE_SOON',
  };

  Widget _todoGrid(List<TaskCard> cards) {
    if (cards.isEmpty) return const EmptyState('Nothing on the to-do list today');
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpace.s3,
      crossAxisSpacing: AppSpace.s3,
      childAspectRatio: 1.15,
      children: [for (final c in cards) _todoCard(c)],
    );
  }

  Widget _todoCard(TaskCard c) {
    final accent = c.priority == 'HIGH'
        ? AppColors.adaptive(context, AppColors.blockFg)
        : c.priority == 'MEDIUM'
            ? AppColors.adaptive(context, AppColors.warnFg)
            : AppColors.adaptive(context, AppColors.focus);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          final bucket = _feeBucketByCardKey[c.key];
          if (bucket != null) {
            _openFeeBucket(bucket, c.label.isEmpty ? c.title : c.label);
            return;
          }
          // Neither Inquiries nor Today's Classes is a founder sidebar item
          // (brief §11.13: no new nav options) — pushed as standalone
          // screens instead, same pattern as the fee-bucket drill-down.
          // Both fall back to every branch when auth.branch is null, which
          // it always is for a founder session. Neither screen carries its
          // own Scaffold (they expect the drawer shell's app bar), so one is
          // added here rather than in the shared widget.
          switch (c.targetView) {
            case 'inquiries':
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(appBar: AppBar(title: const Text('Inquiries')), body: const InquiriesScreen()),
              ));
              return;
            case 'todayClasses':
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(appBar: AppBar(title: const Text("Today's Classes")), body: const TodaysClassesScreen()),
              ));
              return;
            case 'students':
              ShellNavigator.of(context).go('students');
              return;
            default:
              ShellNavigator.of(context).go('approvals');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(bottom: AppSpace.s2),
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            Text(c.label.isEmpty ? c.title : c.label,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${c.count ?? 0}',
                style: AppType.figure.copyWith(fontSize: 27, color: c.needsAttention ? accent : AppColors.adaptive(context, AppColors.muted))),
          ]),
        ),
      ),
    );
  }

  String _time12(String t) {
    final p = t.split(':');
    if (p.length < 2) return t;
    final h = int.tryParse(p[0]) ?? 0;
    final suffix = h >= 12 ? 'pm' : 'am';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${p[1]}$suffix';
  }

  Widget _lecturesCard(TodaysLecturesSummary l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${l.count}', style: AppType.figure.copyWith(fontSize: 22)),
            const SizedBox(width: AppSpace.s2),
            Text('classes today', style: TextStyle(fontSize: 13, color: AppColors.adaptive(context, AppColors.muted))),
            const Spacer(),
            if (l.unanswered > 0) StatusBadge('${l.unanswered} UNANSWERED') else if (l.count > 0) const StatusBadge('ALL ANSWERED'),
          ]),
          if (l.rows.isEmpty)
            Padding(padding: const EdgeInsets.only(top: AppSpace.s2), child: Text('Nothing on the timetable today.', style: TextStyle(fontSize: 12.5, color: AppColors.adaptive(context, AppColors.muted))))
          else
            for (final c in l.rows)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s2),
                child: Row(children: [
                  SizedBox(width: 52, child: Text(_time12(c.startTime), style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted)))),
                  Expanded(
                    child: Text('${c.course}${c.teacherName.isNotEmpty ? ' · ${c.teacherName}' : ''}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  ),
                  StatusBadge(c.resolved ? c.outcome : 'PENDING'),
                ]),
              ),
        ]),
      ),
    );
  }

  Widget _attendanceCard(AttendanceTodaySummary a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${a.marked}', style: AppType.figure.copyWith(fontSize: 22)),
            Text('/${a.totalActive}', style: TextStyle(fontSize: 13, color: AppColors.adaptive(context, AppColors.muted))),
            const SizedBox(width: AppSpace.s2),
            Text('marked today', style: TextStyle(fontSize: 13, color: AppColors.adaptive(context, AppColors.muted))),
          ]),
          const SizedBox(height: AppSpace.s2),
          Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
            if (a.present > 0) TagChip('${a.present} present', color: AppColors.adaptive(context, AppColors.okFg)),
            if (a.absent > 0) TagChip('${a.absent} absent', color: AppColors.adaptive(context, AppColors.blockFg)),
            if (a.late > 0) TagChip('${a.late} late', color: AppColors.adaptive(context, AppColors.warnFg)),
            if (a.excused > 0) TagChip('${a.excused} excused', color: AppColors.adaptive(context, AppColors.muted)),
            if (a.notMarked > 0) TagChip('${a.notMarked} not marked', color: AppColors.adaptive(context, AppColors.muted)),
          ]),
        ]),
      ),
    );
  }

  Widget _enquiriesCard(EnquiriesSummary e) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${e.openCount}', style: AppType.figure.copyWith(fontSize: 22)),
            const SizedBox(width: AppSpace.s2),
            Text('open enquiries', style: TextStyle(fontSize: 13, color: AppColors.adaptive(context, AppColors.muted))),
            const Spacer(),
            if (e.callTodayCount > 0) TagChip('${e.callTodayCount} to call today', color: AppColors.adaptive(context, AppColors.focus)),
          ]),
          if (e.rows.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s2),
            for (final r in e.rows)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(r.name.isNotEmpty ? '${r.name} · ${r.phone}' : r.phone, style: const TextStyle(fontSize: 12.5)),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _teacherAttendanceCard(TeacherAttendanceSummary t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (t.teachers.isEmpty)
            Text('No teacher has a class scheduled today.', style: TextStyle(fontSize: 12.5, color: AppColors.adaptive(context, AppColors.muted)))
          else
            for (final row in t.teachers)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s2),
                child: Row(children: [
                  Expanded(
                    child: Text(row.teacherName.isNotEmpty ? row.teacherName : row.teacherId,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  ),
                  Wrap(spacing: 6, children: [
                    if (row.held > 0) TagChip('${row.held} held', color: AppColors.adaptive(context, AppColors.okFg)),
                    if (row.substituted > 0) TagChip('${row.substituted} subbed', color: AppColors.adaptive(context, AppColors.focus)),
                    if (row.cancelled > 0) TagChip('${row.cancelled} cancelled', color: AppColors.adaptive(context, AppColors.blockFg)),
                    if (row.unanswered > 0) TagChip('${row.unanswered} pending', color: AppColors.adaptive(context, AppColors.warnFg)),
                  ]),
                ]),
              ),
        ]),
      ),
    );
  }

  Widget _moneyRow(DashboardMetrics m) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: const [AppShadows.card],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('COLLECTED TODAY',
              style: AppType.eyebrow.copyWith(color: Colors.white.withValues(alpha: .7))),
          const SizedBox(height: AppSpace.s2),
          Text(inr(m.todayCollection),
              style: AppType.numbers.copyWith(fontSize: 34, color: dark ? AppColors.dPrimary : AppColors.brass)),
          const SizedBox(height: AppSpace.s3),
          // Wraps instead of overflowing once the month total grows (₹1,84,500
          // already ran off the card on a 360dp phone).
          Wrap(
            spacing: AppSpace.s2,
            runSpacing: AppSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip('Cash', inr(m.cashToday)),
              _chip('Online', inr(m.onlineToday)),
              Text('Month: ${inr(m.monthCollection)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _tilePair(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: left),
        const SizedBox(width: AppSpace.s3),
        Expanded(child: right),
      ]),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Text('$label $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }

  Widget _bucket(String title, List<DueReminderItem> items, Color accent) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.s3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s3, AppSpace.s4, 0),
          child: Row(children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: accent)),
            const Spacer(),
            Text('${items.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpace.s3),
            child: Text('Nothing here', style: TextStyle(color: AppColors.adaptive(context, AppColors.muted), fontSize: 13)),
          )
        else
          for (final it in items.take(5))
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: 0),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.adaptive(context, AppColors.pageBg),
                child: Text(it.studentName.isNotEmpty ? it.studentName.substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              title: Text(it.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${it.classCode} · ${it.phone}', style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
              trailing: Text(it.nextDueDate, style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
            ),
      ]),
    );
  }

  Widget _receiptTile(ReceiptRow r) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.s2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: 0),
        leading: Icon(Icons.receipt_outlined, color: AppColors.adaptive(context, AppColors.muted)),
        title: Text('${r.receiptNo} · ${r.student}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text('${r.date} · ${r.mode}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: AmountText(r.amount),
      ),
    );
  }
}