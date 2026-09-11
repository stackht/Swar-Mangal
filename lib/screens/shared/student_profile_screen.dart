import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';
import 'fee_collection_screen.dart';
import 'message_compose_screen.dart';

/// Student profile — the shared one-screen view of a student for both apps.
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key, required this.student, required this.staff});
  final Student student;
  final bool staff;
  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  List<ReceiptRow> _receipts = [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = widget.staff
          ? await auth.service!.searchReceipts(
              q: widget.student.studentName,
              classCode: _classFor(auth.branch ?? ''),
            )
          : await auth.service!.searchReceipts(studentName: widget.student.studentName);
      if (!mounted) return;
      setState(() {
        _receipts = rows;
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

  String _classFor(String branch) {
    if (branch == 'KANDIVALI') return 'KMC';
    if (branch == 'GOREGAON') return 'GMC';
    return 'ALL';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      appBar: AppBar(title: Text(s.studentName)),
      body: RefreshScaffold(
        onRefresh: _loadReceipts,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s4),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: .08),
                    child: Text(s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ),
                  const SizedBox(height: AppSpace.s3),
                  Text(s.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpace.s1),
                  Text(s.studentId, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: AppSpace.s2),
                  Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
                    TagChip(s.classCode),
                    if (s.instrument.isNotEmpty) TagChip(s.instrument, color: AppColors.focus),
                    StatusBadge(s.feeStatus),
                  ]),
                ]),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(children: [
                  InfoRow('Phone', s.phone.isNotEmpty ? s.phone : '—'),
                  InfoRow('Email', s.email.isNotEmpty ? s.email : '—'),
                  InfoRow('Batch / Class', s.batch.isNotEmpty ? s.batch : '—'),
                  InfoRow('Teacher', s.teacher.isNotEmpty ? s.teacher : '—'),
                  InfoRow('Fee plan', s.feeCycleType.isNotEmpty ? s.feeCycleType : '—'),
                  InfoRow('Next due', s.nextDueDate.isNotEmpty ? s.nextDueDate : '—'),
                  InfoRow('Last receipt', s.lastReceiptNo.isNotEmpty ? '${s.lastReceiptNo} · ₹${s.lastReceiptAmount}' : '—'),
                ]),
              ),
            ),
            const SizedBox(height: AppSpace.s3),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FeeCollectionScreen(staff: widget.staff, prefill: s),
              )),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Collect / record fee'),
            ),
            const SizedBox(height: AppSpace.s3),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.focus),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MessageComposeScreen(
                  staff: widget.staff,
                  studentId: s.studentId,
                  studentName: s.studentName,
                  instrument: s.instrument,
                  branch: s.classCode,
                ),
              )),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('Message parent'),
            ),
            SectionTitle('Receipts${_busy ? ' …' : ''}'),
            if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(AppSpace.s3), child: ErrorView(_error!, onRetry: _loadReceipts, compact: true)))
            else if (_receipts.isEmpty && !_busy)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpace.s5),
                  child: EmptyState('No receipts yet'),
                ),
              )
            else
              for (final r in _receipts.take(15))
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpace.s2),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: 4),
                    leading: const Icon(Icons.receipt_long_outlined, color: AppColors.muted),
                    title: Text(r.receiptNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${r.date} · ${r.mode}${r.excluded ? ' · EXCLUDED' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    trailing: Text(inr(r.amount),
                        style: TextStyle(fontWeight: FontWeight.w800, color: r.excluded ? AppColors.muted : AppColors.primary)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}