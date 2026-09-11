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
  List<PaymentDraftRow> _queue = [];
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
      final results = await Future.wait([
        auth.service!.founderApprovals(),
        auth.service!.founderListPaymentDrafts(),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0] as ApprovalsData;
        _queue = results[1] as List<PaymentDraftRow>;
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

  /// FINALISE — the real-money step: reserves a receipt number, writes
  /// STUDENT_RECEIPTS + MONEY_LEDGER, advances the due date, renders the PDF.
  Future<void> _finalise(PaymentDraftRow row) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    if (_acting.contains(row.draftId)) return;
    final confirm = await _confirm(
      'Create receipt — REAL MONEY',
      'Finalising ${row.draftId} (₹${row.amount}) allocates a receipt number, '
      'writes STUDENT_RECEIPTS + MONEY_LEDGER, advances the due date and '
      'generates the PDF. This is audited and NOT reversible from the app.',
    );
    if (!confirm) return;
    setState(() => _acting.add(row.draftId));
    try {
      final r = await auth.service!.founderFinalisePaymentDraft(row.draftId);
      final m = r as Map<String, dynamic>;
      if (!mounted) return;
      final okRes = m['ok'] == true;
      if (okRes) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('Receipt ${m['receiptNo']} created — ${m['note']}')));
      } else if (m['error'] == 'INCOMPLETE_STUDENT' || m['code'] == 'INCOMPLETE_STUDENT') {
        final missing = (m['missing'] as List?)?.join(', ') ?? 'unknown fields';
        final reason = await _ask(
          'Override incomplete student?',
          'Student is missing: $missing. Type a reason to force finalise (audited).',
        );
        if (reason != null) {
          final r2 = await auth.service!.founderFinalisePaymentDraft(
            row.draftId,
            override: true,
            overrideReason: reason,
          );
          final m2 = r2 as Map<String, dynamic>;
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text(m2['ok'] == true
                    ? 'Receipt ${m2['receiptNo']} created (override)'
                    : (m2['error'] ?? m2['message'] ?? 'Finalise failed'))));
        }
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text((m['message'] ?? m['error'] ?? 'Finalise failed'))));
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      await _load();
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting.remove(row.draftId));
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
          const SectionTitle('Receipts pending'),
          const Text(
            'Approved payments that have not been turned into a receipt yet. '
            'Finalising writes real money records server-side.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpace.s3),
          if (_queue.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpace.s4),
                child: Text('No payment drafts in the queue.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
            )
          else
            for (final row in _queue)
              if (row.approved || row.repairRequired) _draftCard(row),
        ],
      ),
    );
  }

  Widget _draftCard(PaymentDraftRow row) {
    final busy = _acting.contains(row.draftId);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row.studentName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('${row.draftId} · ${row.branch}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
            if (row.amount.isNotEmpty)
              Text('₹${row.amount}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
          const SizedBox(height: AppSpace.s2),
          Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
            StatusBadge(row.status),
            if (row.repairRequired) const StatusBadge('REPAIR REQUIRED'),
            if (row.paymentMode.isNotEmpty) TagChip(row.paymentMode, color: AppColors.focus),
            if (row.projectNextDueDate.isNotEmpty)
              TagChip('→ due ${row.projectNextDueDate}', color: AppColors.muted),
          ]),
          const SizedBox(height: AppSpace.s3),
          Row(children: [
            _actionBtn(
              row.repairRequired ? 'Repair (founder web)' : 'Create receipt',
              AppColors.primary,
              busy,
              row.repairRequired
                  ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Repair is done on the founder web app — the block names the missing data.')))
                  : () => _finalise(row),
            ),
          ]),
        ]),
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