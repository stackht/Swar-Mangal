import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/sync_manager.dart';

import '../../../core/api.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../state/auth_provider.dart';
import '../../../widgets/atoms.dart';
import '../../../widgets/music_mark.dart';
import '../../shell/shell_nav.dart';

/// Staff Today: the ordered task cards the backend computes for this branch.
/// Cards with a count > 0 are actionable; tapping opens the matching view.
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

class _BodyState extends State<_Body> with SyncAware
  @override
  Set<String> get syncEntities => { 'tasks', 'dashboard', 'attendance' };

  @override
  Future<void> reloadFromSync() => _fetch; with SyncAware
  @override
  Set<String> get syncEntities => { 'tasks', 'dashboard', 'attendance' };

  @override
  Future<void> reloadFromSync() => _fetch; {
  List<TaskCard>? _cards;
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
      final cards = await widget.auth.service!
          .staffTodaysTasks(branch: widget.auth.branch!);
      if (!mounted) return;
      setState(() {
        _cards = cards;
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
    if (_busy && _cards == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _cards == null) {
      return ErrorView(_error!, onRetry: _fetch);
    }
    final scheme = Theme.of(context).colorScheme;
    final list = ListView(
      padding: const EdgeInsets.all(AppSpace.s4),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow('${widget.auth.branch} · today'),
              Text('Your day, at a glance.',
                  style: AppType.display.copyWith(
                    fontSize: 22,
                    color: scheme.onSurface,
                  )),
            ]),
          ),
          WaveformMark(active: true, height: 24, color: scheme.primary),
        ]),
        const SizedBox(height: AppSpace.s4),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.s3,
          crossAxisSpacing: AppSpace.s3,
          childAspectRatio: 1.45,
          children: [
            for (final c in _cards ?? const []) _card(c),
          ],
        ),
        const SizedBox(height: AppSpace.s4),
        if (_cards == null || _cards!.isEmpty)
          const EmptyState('No tasks for today'),
        Text(
          'Task counts are computed server-side from live data. Nothing on this '
          'screen changes money or sends messages.',
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    );
    return RefreshScaffold(onRefresh: _fetch, child: list);
  }

  Widget _card(TaskCard c) {
    final accent = c.priority == 'HIGH'
        ? AppColors.blockFg
        : c.priority == 'MEDIUM'
            ? AppColors.warnFg
            : AppColors.focus;
    final count = c.count;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: c.needsAttention ? () => _open(c.targetView) : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.circle, size: 10, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(c.label.isEmpty ? c.title : c.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ]),
              const Spacer(),
              Text(
                count == null ? '—' : '$count',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.needsAttention ? accent : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(String target) {
    // Tiles announce the view they would open; the shell switches to the
    // closest staff nav destination.
    final map = <String, String>{
      'students': 'students',
      'myRequests': 'students',
      'comm': 'today',
      'terms': 'students',
      'extension': 'students',
      'approvals': 'today',
      'inquiries': 'inquiries',
    };
    final key = map[target] ?? 'today';
    ShellNavigator.of(context).go(key);
  }
}