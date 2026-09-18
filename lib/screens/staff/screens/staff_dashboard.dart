import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/sync_manager.dart';

import '../../../core/api.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../state/auth_provider.dart';
import '../../../widgets/atoms.dart';
import '../../shared/fee_bucket_screen.dart';
import '../../shell/shell_nav.dart';

/// Staff Today: fees due, the to-do grid, today's lectures, attendance,
/// enquiries and teacher attendance — one server round trip
/// (api_staff_todaysTasks), rendered as sections rather than one flat grid.
class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return _Body(auth: auth);
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.auth});
  final AuthProvider auth;
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SyncAware {
  @override
  Set<String> get syncEntities => const {'tasks', 'dashboard', 'attendance', 'sessions', 'inquiries'};

  @override
  Future<void> reloadFromSync() => _fetch();

  StaffToday? _today;
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
      final today = await widget.auth.service!
          .staffTodaysTasks(branch: widget.auth.branch!);
      if (!mounted) return;
      setState(() {
        _today = today;
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

  // The fee cards already get their own section above the grid.
  static const _todoOnly = {'DELIVERY_NOT_MARKED', 'PAYMENT_PENDING', 'CALL_TODAY', 'WAITING_FOR_SHARVIL', 'FEE_PLAN_MISSING'};

  @override
  Widget build(BuildContext context) {
    if (_busy && _today == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _today == null) {
      return ErrorView(_error!, onRetry: _fetch);
    }
    final scheme = Theme.of(context).colorScheme;
    final t = _today;
    final overview = t?.overview;
    final todoCards = (t?.cards ?? const []).where((c) => _todoOnly.contains(c.key)).toList();
    final list = ListView(
      padding: const EdgeInsets.all(AppSpace.s4),
      children: [
        PageHero(eyebrow: '${widget.auth.branch} · today', headline: 'Your day, at a glance.', fontSize: 22),
        const SizedBox(height: AppSpace.s4),
        if (overview != null) ...[
          const SectionTitle('Fees due today'),
          _feesDueCard(overview.feesDueToday),
          const SectionTitle("Today's to-do"),
        ],
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.s3,
          crossAxisSpacing: AppSpace.s3,
          childAspectRatio: 1.15,
          children: [for (final c in todoCards) _card(c)],
        ),
        if (overview != null) ...[
          const SectionTitle("Today's lectures"),
          _lecturesCard(overview.todaysLectures),
          const SectionTitle('Attendance'),
          _attendanceCard(overview.attendance),
          const SectionTitle('Enquiries'),
          _enquiriesCard(overview.enquiries),
          const SectionTitle('Teacher attendance'),
          _teacherAttendanceCard(overview.teacherAttendance),
        ],
        const SizedBox(height: AppSpace.s3),
        Text(
          'Every figure above is computed server-side from live data. Nothing on this '
          'screen changes money or sends messages.',
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    );
    return RefreshScaffold(onRefresh: _fetch, child: list);
  }

  // ------------------------------------------------------------- fees due
  Widget _feesDueCard(FeesDueTodaySummary f) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => _openFeeBucket('DUE_TODAY', 'Fees Due Today'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.s2,
              runSpacing: AppSpace.s2,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${f.count}', style: AppType.figure.copyWith(fontSize: 30, color: f.count > 0 ? AppColors.adaptive(context, AppColors.warnFg) : AppColors.adaptive(context, AppColors.muted))),
                  const SizedBox(width: AppSpace.s2),
                  Text('due today', style: TextStyle(fontSize: 13, color: AppColors.adaptive(context, AppColors.muted))),
                ]),
                if (f.overdueCount > 0)
                  GestureDetector(
                    onTap: () => _openFeeBucket('OVERDUE', 'Fees Overdue'),
                    child: TagChip('${f.overdueCount} overdue', color: AppColors.adaptive(context, AppColors.blockFg)),
                  ),
                if (f.dueSoonCount > 0)
                  GestureDetector(
                    onTap: () => _openFeeBucket('DUE_SOON', 'Fees Upcoming'),
                    child: TagChip('${f.dueSoonCount} upcoming', color: AppColors.adaptive(context, AppColors.focus)),
                  ),
              ],
            ),
            if (f.rows.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s2),
              for (final r in f.rows)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${r.studentName} · ${r.classCode}', style: const TextStyle(fontSize: 12.5)),
                ),
            ],
          ]),
        ),
      ),
    );
  }

  void _openFeeBucket(String bucket, String title) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FeeBucketScreen(bucket: bucket, title: title, staff: true),
    ));
  }

  // -------------------------------------------------------------- to-do grid
  Widget _card(TaskCard c) {
    final accent = c.priority == 'HIGH'
        ? AppColors.adaptive(context, AppColors.blockFg)
        : c.priority == 'MEDIUM'
            ? AppColors.adaptive(context, AppColors.warnFg)
            : AppColors.adaptive(context, AppColors.focus);
    final count = c.count;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => _openCard(c),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(bottom: AppSpace.s2),
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              Text(c.label.isEmpty ? c.title : c.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                count == null ? '—' : '$count',
                style: AppType.figure.copyWith(
                  fontSize: 27,
                  color: c.needsAttention ? accent : AppColors.adaptive(context, AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- today's lectures
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
          const SizedBox(height: AppSpace.s2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => ShellNavigator.of(context).go('todayClasses'), child: const Text('Open Today\'s Classes')),
          ),
        ]),
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

  // -------------------------------------------------------------- attendance
  Widget _attendanceCard(AttendanceTodaySummary a) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => ShellNavigator.of(context).go('attendance'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${a.marked}', style: AppType.figure.copyWith(fontSize: 22)),
              Text('/${a.totalActive}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(width: AppSpace.s2),
              const Text('marked today', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            ]),
            const SizedBox(height: AppSpace.s2),
            Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
              if (a.present > 0) TagChip('${a.present} present', color: AppColors.okFg),
              if (a.absent > 0) TagChip('${a.absent} absent', color: AppColors.blockFg),
              if (a.late > 0) TagChip('${a.late} late', color: AppColors.warnFg),
              if (a.excused > 0) TagChip('${a.excused} excused', color: AppColors.muted),
              if (a.notMarked > 0) TagChip('${a.notMarked} not marked', color: AppColors.muted),
            ]),
          ]),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- enquiries
  Widget _enquiriesCard(EnquiriesSummary e) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => ShellNavigator.of(context).go('inquiries'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${e.openCount}', style: AppType.figure.copyWith(fontSize: 22)),
              const SizedBox(width: AppSpace.s2),
              const Text('open enquiries', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const Spacer(),
              if (e.callTodayCount > 0) TagChip('${e.callTodayCount} to call today', color: AppColors.focus),
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
      ),
    );
  }

  // ------------------------------------------------------- teacher attendance
  Widget _teacherAttendanceCard(TeacherAttendanceSummary t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (t.teachers.isEmpty)
            const Text('No teacher has a class scheduled today.', style: TextStyle(fontSize: 12.5, color: AppColors.muted))
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
                    if (row.held > 0) TagChip('${row.held} held', color: AppColors.okFg),
                    if (row.substituted > 0) TagChip('${row.substituted} subbed', color: AppColors.focus),
                    if (row.cancelled > 0) TagChip('${row.cancelled} cancelled', color: AppColors.blockFg),
                    if (row.unanswered > 0) TagChip('${row.unanswered} pending', color: AppColors.warnFg),
                  ]),
                ]),
              ),
        ]),
      ),
    );
  }

  static const _feeBuckets = {
    'FEES_OVERDUE': 'OVERDUE',
    'FEES_DUE_TODAY': 'DUE_TODAY',
    'FEES_DUE_SOON': 'DUE_SOON',
  };

  void _openCard(TaskCard c) {
    // Fee cards open exactly the students they count, not the whole list.
    final bucket = _feeBuckets[c.key];
    if (bucket != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FeeBucketScreen(bucket: bucket, title: c.label.isEmpty ? c.title : c.label, staff: true),
      ));
      return;
    }
    _open(c.targetView);
  }

  void _open(String target) {
    // Tiles announce the view they would open; the shell switches to the
    // closest staff nav destination. Every card is clickable.
    final map = <String, String>{
      'students': 'students',
      'myRequests': 'requests',
      'requests': 'requests',
      'comm': 'today',
      'terms': 'students',
      'extension': 'students',
      'approvals': 'addFee',
      'inquiries': 'inquiries',
      'attendance': 'attendance',
      'receipts': 'receipts',
      'expenses': 'expenses',
      'teachers': 'teachers',
      'timetable': 'timetable',
      'todayClasses': 'todayClasses',
      'fees': 'addFee',
      'payments': 'receipts',
    };
    final key = map[target] ?? 'today';
    ShellNavigator.of(context).go(key);
  }
}
