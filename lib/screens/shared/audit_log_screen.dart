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

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    if (_busy && _rows.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _rows.isEmpty) return ErrorView(_error!, onRetry: _load);

    return RefreshScaffold(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Row(children: [
            const Icon(Icons.history_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpace.s2),
            const Expanded(
              child: Text('Activity log',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
          const Text(
              'Every change made through the app, newest first. Record ids only — '
              'no names, amounts or phone numbers are stored here.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
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
                      color: e.ok ? AppColors.okFg : AppColors.blockFg,
                    ),
                    const SizedBox(width: AppSpace.s2),
                    Expanded(
                      child: Text(e.action,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    Text(e.whenLabel,
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
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
                      color: e.ok ? AppColors.muted : AppColors.blockFg,
                    ),
                  ),
                  if (e.ref.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(e.ref,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
