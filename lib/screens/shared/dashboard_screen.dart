import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../state/auth_provider.dart';
import '../../../widgets/anim.dart';
import '../../../widgets/atoms.dart';
import '../../../widgets/music_mark.dart';

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

class _BodyState extends State<_Body> {
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
    final scheme = Theme.of(context).colorScheme;
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
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Eyebrow('Today'),
                    Text('Good ${_greeting()}.',
                        style: AppType.display.copyWith(
                          fontSize: 26,
                          color: scheme.onSurface,
                        )),
                  ]),
                ),
                WaveformMark(active: true, height: 28, color: scheme.primary),
              ]),
              const SizedBox(height: AppSpace.s4),
              if (m != null) ...[
                _moneyRow(m),
                const SizedBox(height: AppSpace.s3),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.7,
                  mainAxisSpacing: AppSpace.s3,
                  crossAxisSpacing: AppSpace.s3,
                  children: [
                    StatTile(label: 'Due Today', value: '${m.dueTodayCount}', icon: Icons.today, accent: AppColors.warnFg),
                    StatTile(label: 'Overdue', value: '${m.overdueCount}', icon: Icons.flag_outlined, accent: AppColors.blockFg),
                    StatTile(label: 'Terms Pending', value: '${m.termsPendingCount}', icon: Icons.assignment_outlined),
                    StatTile(label: 'This Month', value: '${m.monthCount} rct', icon: Icons.receipt_outlined, accent: AppColors.focus),
                  ],
                ),
                const SectionTitle('Recent receipts'),
                for (final r in m.recent.take(6)) _receiptTile(r),
                if (m.recent.isEmpty) const EmptyState('No receipt activity yet'),
              ],
              if (d != null && d.count > 0) ...[
                const SectionTitle('Fee buckets'),
                _bucket('Due today', d.dueToday, AppColors.warnFg),
                _bucket('Overdue', d.overdue, AppColors.blockFg),
                _bucket('Due soon', d.dueSoon, AppColors.infoFg),
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

  Widget _moneyRow(DashboardMetrics m) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('COLLECTED TODAY',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpace.s2),
          Text(inr(m.todayCollection), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: AppSpace.s2),
          Row(children: [
            _chip('Cash', inr(m.cashToday), AppColors.okFg),
            const SizedBox(width: AppSpace.s2),
            _chip('Online', inr(m.onlineToday), AppColors.focus),
            const Spacer(),
            Text('Month: ${inr(m.monthCollection)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2, vertical: 4),
      decoration: BoxDecoration(color: AppColors.pageBg, borderRadius: BorderRadius.circular(6)),
      child: Text('$label $value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
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
          const Padding(
            padding: EdgeInsets.all(AppSpace.s3),
            child: Text('Nothing here', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          )
        else
          for (final it in items.take(5))
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: 0),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.pageBg,
                child: Text(it.studentName.isNotEmpty ? it.studentName.substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              title: Text(it.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${it.classCode} · ${it.phone}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              trailing: Text(it.nextDueDate, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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
        leading: const Icon(Icons.receipt_outlined, color: AppColors.muted),
        title: Text('${r.receiptNo} · ${r.student}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text('${r.date} · ${r.mode}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: AmountText(r.amount),
      ),
    );
  }
}