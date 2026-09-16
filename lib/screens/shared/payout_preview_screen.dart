import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Founder payout preview — server-computed teacher earning / payable / balance.
/// No client payout logic. Displays `api_teacherPayoutPreview` rows.
/// Business rules: NEVER calculate payout on device; amount/rate from server.
class PayoutPreviewScreen extends StatefulWidget {
  const PayoutPreviewScreen({super.key});
  @override
  State<PayoutPreviewScreen> createState() => _PayoutPreviewScreenState();
}

class _PayoutPreviewScreenState extends State<PayoutPreviewScreen> {
  late String _month;
  List<PayoutRow> _rows = [];
  List<SharedStudentDecision> _awaiting = const [];
  num _awaitingAmount = 0;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _month = _currentMonth();
    _load();
  }

  String _currentMonth() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  String _previousMonth() {
    final d = DateTime(DateTime.now().year, DateTime.now().month - 1);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await auth.service!.founderPayoutPreviewFull(_month);
      if (!mounted) return;
      setState(() {
        _rows = preview.rows;
        _awaiting = preview.awaitingDecision;
        _awaitingAmount = preview.awaitingAmount;
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

    final totalPayable = _rows.fold<num>(0, (s, r) => s + r.payable);
    final totalPaid = _rows.fold<num>(0, (s, r) => s + r.alreadyPaid);
    final totalBalance = _rows.fold<num>(0, (s, r) => s + r.balance);

    return RefreshScaffold(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Row(children: [
            const Icon(Icons.payments_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpace.s2),
            const Text('Teacher payouts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: AppSpace.s3),
          Row(children: [
            Expanded(
              child: _monthInput('Service month (YYYY-MM)', _month, (v) {
                setState(() => _month = v);
                _load();
              }),
            ),
            const SizedBox(width: AppSpace.s2),
            TextButton(onPressed: () { setState(() => _month = _previousMonth()); _load(); },
                child: const Text('Previous')),
          ]),
          const SizedBox(height: AppSpace.s2),
          Card(
            color: AppColors.infoBg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s3),
              child: Text(
                  'Figures below are server-computed from actual receipt shares. '
                  'The app does not calculate payouts — it displays the backend\'s authoritative numbers only.',
                  style: const TextStyle(fontSize: 12, color: AppColors.infoFg)),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          Row(children: [
            _metric('Payable', inr(totalPayable), AppColors.primary),
            const SizedBox(width: AppSpace.s2),
            _metric('Paid', inr(totalPaid), AppColors.okFg),
            const SizedBox(width: AppSpace.s2),
            _metric('Balance', inr(totalBalance), totalBalance > 0 ? AppColors.warnFg : AppColors.muted),
          ]),
          const SizedBox(height: AppSpace.s4),
          if (_awaiting.isNotEmpty) ...[
            Card(
              color: AppColors.warnBg,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.call_split_outlined, size: 18, color: AppColors.warnFg),
                    const SizedBox(width: AppSpace.s2),
                    Expanded(
                      child: Text('Waiting for your decision · ${inr(_awaitingAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.warnFg)),
                    ),
                  ]),
                  const SizedBox(height: AppSpace.s2),
                  const Text(
                      'These students were taught by more than one teacher this month. '
                      'Their fees count for nobody until you split them, so no payout is overstated.',
                      style: TextStyle(fontSize: 12, color: AppColors.warnFg)),
                  for (final sharedStudent in _awaiting) ...[
                    const SizedBox(height: AppSpace.s3),
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(sharedStudent.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                              'paid ${inr(sharedStudent.collected)} · unassigned ${inr(sharedStudent.remaining)} · '
                              '${sharedStudent.teachers.map((t) => '${t.teacherName} (${t.classesThisMonth})').join(', ')}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        ]),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => _splitShared(sharedStudent),
                        child: const Text('Split'),
                      ),
                    ]),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: AppSpace.s4),
          ],
          if (_rows.isEmpty)
            const EmptyState('No payout rows for this month.'),
          for (final r in _rows)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpace.s3),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.teacherName.isNotEmpty ? r.teacherName : r.teacherId,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text('${r.entityId} · ${r.month} · ${r.receiptCount} receipts',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                    StatusBadge(r.preCutover ? 'PRE-CUTOVER' : r.status.isEmpty ? 'NONE' : r.status),
                  ]),
                  if (r.preCutover && r.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.s2),
                      child: Text(r.note, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ),
                  const SizedBox(height: AppSpace.s2),
                  Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
                    _tag('collected', inr(r.totalCollection)),
                    _tag('share', inr(r.totalTeacherShare)),
                    _tag('paid', inr(r.alreadyPaid)),
                    _tag('balance', inr(r.balance)),
                  ]),
                  if (r.balance > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _busy ? null : () => _recordPayment(r),
                        icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                        label: const Text('Record payment'),
                      ),
                    ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  /// Decide how a shared student's fee splits between the teachers who taught
  /// them this month. Amounts start empty — the class counts are shown as
  /// context, not as a suggested answer.
  Future<void> _splitShared(SharedStudentDecision shared) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    final controllers = {
      for (final t in shared.teachers)
        t.teacherId: TextEditingController(text: t.assigned > 0 ? t.assigned.toStringAsFixed(0) : ''),
    };

    num entered() => controllers.values
        .fold<num>(0, (sum, c) => sum + (num.tryParse(c.text.trim()) ?? 0));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final left = shared.collected - entered();
          return AlertDialog(
            title: Text('Split ${shared.studentName}'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Paid ${inr(shared.collected)} in $_month',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: AppSpace.s3),
              for (final t in shared.teachers)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s2),
                  child: TextField(
                    controller: controllers[t.teacherId],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setLocal(() {}),
                    decoration: InputDecoration(
                      labelText: '${t.teacherName} · ${t.classesThisMonth} classes',
                      prefixText: '₹ ',
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  left < 0 ? 'Over by ${inr(-left)}' : 'Unassigned ${inr(left)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: left < 0 ? AppColors.blockFg : AppColors.muted,
                  ),
                ),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: left < 0 ? null : () => Navigator.pop(ctx, true),
                child: const Text('Save split'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await auth.service!.assignSharedStudent(
        month: _month,
        studentId: shared.studentId,
        allocations: {
          for (final entry in controllers.entries) entry.key: num.tryParse(entry.value.text.trim()) ?? 0,
        },
      );
      if (!mounted) return;
      _toast('Split saved for ${shared.studentName}.');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(e.message);
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(e.message);
    }
  }

  /// Record money actually paid to a teacher. The amount defaults to the
  /// outstanding balance; the backend posts the cashbook entry.
  Future<void> _recordPayment(PayoutRow r) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    final amountCtl = TextEditingController(text: r.balance.toStringAsFixed(0));
    final refCtl = TextEditingController();
    var mode = 'Bank Transfer';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Pay ${r.teacherName.isNotEmpty ? r.teacherName : r.teacherId}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Service month ${r.month} · balance ${inr(r.balance)}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: AppSpace.s3),
            TextField(
              controller: amountCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount paid', prefixText: '₹ '),
            ),
            const SizedBox(height: AppSpace.s2),
            DropdownButtonFormField<String>(
              initialValue: mode,
              decoration: const InputDecoration(labelText: 'Payment mode'),
              items: const [
                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
              ],
              onChanged: (v) => setLocal(() => mode = v ?? mode),
            ),
            const SizedBox(height: AppSpace.s2),
            TextField(
              controller: refCtl,
              decoration: const InputDecoration(labelText: 'Reference (optional)'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Record')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final amount = num.tryParse(amountCtl.text.trim()) ?? 0;
    if (amount <= 0) {
      _toast('Enter an amount greater than zero.');
      return;
    }
    setState(() => _busy = true);
    try {
      final paid = await auth.service!.recordTeacherPayout(
        teacherId: r.teacherId,
        month: r.month,
        amount: amount,
        paymentMode: mode,
        reference: refCtl.text.trim(),
      );
      if (!mounted) return;
      _toast('Recorded ${inr(paid.amount)} for ${r.teacherName}.');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(e.message);
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(e.message);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _monthInput(String label, String value, ValueChanged<String> onChanged) {
    final c = TextEditingController(text: value);
    return TextField(
      controller: c,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_month_outlined)),
      onSubmitted: onChanged,
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ]),
        ),
      ),
    );
  }

  Widget _tag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label $value', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
    );
  }
}