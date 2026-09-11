import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Staff "My Requests" — shows submitted drafts + status per the reference
/// (api_staff_listMyApprovals). Approval is founder-only.
/// Business rule #5: staff proposal → submitted → founder decides. This
/// screen is read-only status for the operator.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});
  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<ApprovalRequestRow> _rows = [];
  String? _error;
  bool _busy = true;

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
      final rows = await auth.service!.staffMyRequests(branch: auth.branch ?? 'ALL');
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

    final waiting = _rows.where((r) => r.waiting).length;

    return RefreshScaffold(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Row(children: [
            const Icon(Icons.outbox_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpace.s2),
            Text('My requests', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(width: AppSpace.s2),
            if (waiting > 0) Badge(text: '$waiting pending', color: AppColors.warnBg),
          ]),
          const SizedBox(height: AppSpace.s2),
          const Card(
            color: AppColors.infoBg,
            child: Padding(
              padding: EdgeInsets.all(AppSpace.s3),
              child: Text(
                  'Approval is founder-only. These are your submitted drafts — '
                  'their status reflects the current queue. No edits are possible here.',
                  style: TextStyle(fontSize: 12, color: AppColors.infoFg)),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          if (_rows.isEmpty)
            const EmptyState('No requests submitted from this branch.', icon: Icons.outbox_outlined),
          for (final row in _rows)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpace.s3),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    TagChip(row.type.replaceAll('_', ' ')),
                    const SizedBox(width: AppSpace.s2),
                    Expanded(child: Text(row.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                    StatusBadge(row.status.isEmpty ? 'UNKNOWN' : row.status),
                  ]),
                  if (row.student.isNotEmpty || row.category.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.s2),
                      child: Text(
                          [row.student, row.category].where((e) => e.isNotEmpty).join(' · '),
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ),
                  Row(children: [
                    if (row.amount.isNotEmpty)
                      Text('₹${row.amount}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const Spacer(),
                    if (row.backdated)
                      TagChip('BACKDATED', color: AppColors.blockFg),
                    if (row.when.isNotEmpty)
                      Text(row.when, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ]),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tiny helper for a count badge (inline with text).
class Badge extends StatelessWidget {
  const Badge({super.key, required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      );
}