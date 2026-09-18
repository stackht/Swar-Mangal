import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Founder-only activity log: every write the backend recorded, newest first.
/// Read-only, and ids only — the trail never carries names or amounts.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});
  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditEntry> _rows = const [];
  bool _failuresOnly = false;
  bool _busy = false;
  String? _error;

  Map<String, dynamic>? _locks;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadLocks();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await auth.service!.founderAuditLog(failuresOnly: _failuresOnly);
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  Future<void> _loadLocks() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    try {
      final r = await auth.service!.raw('api_founder_periodLocks');
      if (!mounted) return;
      final m = r as Map<String, dynamic>;
      if (m['ok'] == true) setState(() => _locks = m);
    } on ApiException {
      // the activity log still works without this panel
    } on ApiUnreachable {
      // same
    }
  }

  Future<void> _closeMonth(String month, String label) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null || _closing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Close $label?'),
        content: const Text(
            'This locks every dated write in that month — attendance, fees, expenses, classes. It cannot be reopened from the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close month')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _closing = true);
    try {
      final r = await auth.service!.raw('api_founder_closeMonth', {'month': month});
      final m = r as Map<String, dynamic>;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text((m['note'] ?? m['error'] ?? 'Done').toString())));
      await _loadLocks();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy && _rows.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _rows.isEmpty) return ErrorView(_error!, onRetry: _load);

    return RefreshScaffold(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          const PageHero(eyebrow: 'Founder', headline: 'Activity log', fontSize: 22),
          const SizedBox(height: AppSpace.s4),
          if (_locks != null) _periodLockCard(_locks!),
          const SizedBox(height: AppSpace.s4),
          Row(children: [
            const Expanded(
              child: SectionTitle('Write trail'),
            ),
            FilterChip(
              label: const Text('Failures only'),
              selected: _failuresOnly,
              onSelected: _busy
                  ? null
                  : (v) {
                      setState(() => _failuresOnly = v);
                      _load();
                    },
            ),
          ]),
          const SizedBox(height: AppSpace.s2),
          Text(
              'Every change made through the app, newest first. Record ids only — '
              'no names, amounts or phone numbers are stored here.',
              style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
          const SizedBox(height: AppSpace.s4),
          if (_rows.isEmpty)
            EmptyState(_failuresOnly ? 'No failed writes recorded.' : 'Nothing recorded yet.'),
          for (final e in _rows)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpace.s2),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s3),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(
                      e.ok ? Icons.check_circle_outline : Icons.error_outline,
                      size: 18,
                      color: e.ok ? AppColors.adaptive(context, AppColors.okFg) : AppColors.adaptive(context, AppColors.blockFg),
                    ),
                    const SizedBox(width: AppSpace.s2),
                    Expanded(
                      child: Text(e.action,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    Text(e.whenLabel,
                        style: TextStyle(fontSize: 11, color: AppColors.adaptive(context, AppColors.muted))),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    [
                      e.actorRole == 'FOUNDER_ADMIN' ? 'Founder' : 'Staff',
                      if (e.device.isNotEmpty) e.device,
                      if (e.branch.isNotEmpty) e.branch,
                      if (!e.ok && e.code.isNotEmpty) e.code,
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: e.ok ? AppColors.adaptive(context, AppColors.muted) : AppColors.adaptive(context, AppColors.blockFg),
                    ),
                  ),
                  if (e.ref.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(e.ref,
                          style: TextStyle(fontSize: 11, color: AppColors.adaptive(context, AppColors.muted))),
                    ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _periodLockCard(Map<String, dynamic> locks) {
    final nextToClose = (locks['nextToClose'] ?? '').toString();
    final nextLabel = (locks['nextToCloseLabel'] ?? '').toString();
    final unanswered = (locks['unansweredCount'] as num?)?.toInt() ?? 0;
    final rows = (locks['rows'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Service months', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: AppSpace.s2),
          if (nextToClose.isEmpty)
            Text('Every past month is closed.', style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted)))
          else if (unanswered > 0)
            Text(
              '$nextLabel cannot close yet: $unanswered class${unanswered == 1 ? '' : 'es'} not answered.',
              style: TextStyle(fontSize: 12.5, color: AppColors.adaptive(context, AppColors.warnFg), fontWeight: FontWeight.w600),
            )
          else ...[
            Text('$nextLabel has ended and every class is answered.',
                style: TextStyle(fontSize: 12.5, color: AppColors.adaptive(context, AppColors.muted))),
            const SizedBox(height: AppSpace.s3),
            LoadingButton(
              label: 'Close month',
              icon: Icons.lock_outline,
              busy: _closing,
              onPressed: () => _closeMonth(nextToClose, nextLabel),
            ),
          ],
          if (rows.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s3),
            Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
              for (final r in rows.take(6)) TagChip('${r['label']} 🔒', color: AppColors.adaptive(context, AppColors.muted)),
            ]),
          ],
        ]),
      ),
    );
  }
}
