import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Founder approval centre — one list, each row its own decision button.
/// Money (payment drafts) approves via the audited approve endpoint; student
/// drafts merge into the master. Nothing here writes money silently.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});
  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  ApprovalsData? _data;
  String? _error;
  bool _busy = true;
  final Set<String> _acting = {};

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
      final d = await auth.service!.founderApprovals();
      if (!mounted) return;
      setState(() {
        _data = d;
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

  Future<void> _act(ApprovalItem item, String action) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    if (_acting.contains(item.itemId)) return;
    setState(() => _acting.add(item.itemId));
    try {
      if (action == 'reject') {
        final reason = await _ask('Reject ${item.itemId}', 'Reason (required)');
        if (reason == null) return;
        await auth.service!.founderPaymentDraftReject(item.itemId, reason);
      } else if (action == 'approve') {
        await auth.service!.founderPaymentDraftApprove(item.itemId);
      } else if (action == 'merge') {
        final ok = await _confirm('Merge student draft', 'Merge "${item.entity}" into the STUDENTS master?');
        if (!ok) return;
        await auth.service!.founderMergeStudentDraft(item.itemId);
      } else {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${item.itemId} → $action')));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting.remove(item.itemId));
    }
  }

  Future<String?> _ask(String title, String label) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, maxLines: 2, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (c.text.trim().isEmpty) return;
              Navigator.pop(ctx, c.text.trim());
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (_busy && _data == null) return const Center(child: CircularProgressIndicator());
    if (_error != null && _data == null) return ErrorView(_error!, onRetry: _load);
    final d = _data!;
    return RefreshScaffold(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Row(children: [
            const Icon(Icons.fact_check_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpace.s2),
            Text('${d.count} awaiting your authority',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: AppSpace.s4),
          if (d.empty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpace.s5),
                child: EmptyState('Nothing awaiting your approval.', icon: Icons.done_all),
              ),
            ),
          for (final g in d.groups) ...[
            SectionTitle(g.label),
            for (final item in g.items) _itemCard(item),
          ],
        ],
      ),
    );
  }

  Widget _itemCard(ApprovalItem item) {
    final busy = _acting.contains(item.itemId);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.entity, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('${item.itemId} · ${item.date}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
            if (item.amount.isNotEmpty)
              Text('₹${item.amount}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
          const SizedBox(height: AppSpace.s2),
          Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
            if (item.noStudentLinked)
              const StatusBadge('NO STUDENT LINKED')
            else if (item.studentId.isNotEmpty)
              TagChip(item.studentId, color: AppColors.focus),
            if (item.backdated) const StatusBadge('BACKDATED'),
            if (item.incomplete) const StatusBadge('INCOMPLETE'),
            if (item.junk) const StatusBadge('QA/JUNK'),
            if (item.termsStatus.isNotEmpty)
              TagChip(item.termsStatus, color: AppColors.muted),
            StatusBadge(item.reason),
          ]),
          if (item.feesPeriod.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s2),
              child: Text('Period: ${item.feesPeriod}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          const SizedBox(height: AppSpace.s3),
          Row(children: [
            if (item.actions.contains('approve'))
              _actionBtn('Approve', AppColors.okFg, busy, () => _act(item, 'approve')),
            if (item.actions.contains('merge'))
              _actionBtn('Merge', AppColors.okFg, busy, () => _act(item, 'merge')),
            const SizedBox(width: AppSpace.s2),
            if (item.actions.contains('reject'))
              _actionBtn('Reject', AppColors.blockFg, busy, () => _act(item, 'reject')),
          ]),
        ]),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, bool busy, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: .6)),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
      ),
      onPressed: busy ? null : onTap,
      child: busy
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}