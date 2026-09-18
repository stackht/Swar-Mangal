import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';
import 'fee_collection_screen.dart';
import 'instalment_plan_screen.dart';
import 'late_fee_waiver_screen.dart';
import 'message_compose_screen.dart';
import 'package_extension_screen.dart';
import 'pause_membership_screen.dart';
import 'teacher_profile_screen.dart';
import 'terms_screen.dart';

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
  StaffHub? _hub;
  StudentProfileDetail? _detail;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
    _loadDetail();
    if (widget.staff) _loadHub();
  }

  /// Best-effort richer detail (backend profile endpoint). Live deployments
  /// without the endpoint keep the simpler profile — never faked.
  Future<void> _loadDetail() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    try {
      final d = await auth.service!.studentProfile(
        widget.student.studentId,
        branch: auth.branch ?? 'ALL',
      );
      if (!mounted) return;
      setState(() => _detail = d);
    } on ApiException {
      // profile endpoint unavailable — fall back to passed-in Student
    } on ApiUnreachable {
      // same
    }
  }

  Future<void> _loadHub() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    try {
      final hub = await auth.service!.staffStudentHub(
        widget.student.studentId,
        branch: auth.branch ?? 'ALL',
      );
      if (!mounted) return;
      setState(() => _hub = hub);
    } on ApiException {
      // hub is an enhancement — receipts load independently; stay quiet
    } on ApiUnreachable {
      // same
    }
  }

  Future<void> _staffFinalise(PendingFinaliseDraft d) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create receipt now?'),
        content: Text(
            'You are about to create the real receipt for ${d.draftId} (₹${d.amount}) server-side. '
            'The founder already approved it — no further approval needed. This is audited money work.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create receipt')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final r = await auth.service!.staffFinalisePaymentDraft(d.draftId);
      final m = r as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(m['ok'] == true
                ? 'Receipt ${m['receiptNo'] ?? ''} created'
                : (m['message'] ?? m['error'] ?? m['safeError'] ?? 'Could not finalise'))));
      await _loadHub();
      await _loadReceipts();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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

  Future<void> _setStatus(BuildContext context, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    final reason = await _askReason(
      context,
      title: 'Set ${widget.student.studentId} → $status',
      label: 'Reason (required, stored in audit)',
    );
    if (reason == null || reason.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final r = await auth.service!.founderSetStudentStatus(
        widget.student.studentId,
        status,
        reason,
      );
      final m = r as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _busy = false);
      final demoTag = m['demo'] == true ? ' (DEMO — not persisted)' : '';
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(m['ok'] == true
                ? (m['changed'] == true
                    ? '${widget.student.studentId} → $status (audited)$demoTag'
                    : (m['note'] ?? 'No change'))
                : (m['error'] ?? 'Could not change status'))));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<String?> _askReason(BuildContext context,
      {required String title, required String label}) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, maxLines: 2, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        title: Text(s.studentName),
        actions: [
          if (!widget.staff)
            PopupMenuButton<String>(
              tooltip: 'Lifecycle / archive',
              icon: const Icon(Icons.more_vert),
              onSelected: (v) => _setStatus(context, v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'ACTIVE', child: Text('Set ACTIVE')),
                PopupMenuItem(value: 'PAUSED', child: Text('Pause (PAUSED)')),
                PopupMenuItem(value: 'LEFT', child: Text('Mark LEFT (archive)')),
              ],
            ),
        ],
      ),
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
                    backgroundColor: AppColors.adaptive(context, AppColors.primary).withValues(alpha: .08),
                    child: Text(s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.adaptive(context, AppColors.primary))),
                  ),
                  const SizedBox(height: AppSpace.s3),
                  Text(s.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpace.s1),
                  Text(s.studentId, style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
                  const SizedBox(height: AppSpace.s2),
                  Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
                    TagChip(s.classCode),
                    if (s.instrument.isNotEmpty) TagChip(s.instrument, color: AppColors.adaptive(context, AppColors.focus)),
                    StatusBadge(s.status.isEmpty ? s.feeStatus : s.status),
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
                  InfoRow('Plan', planSummary(s.feePlan)),
                  InfoRow('Fee cycle', s.feeCycleType.isNotEmpty ? s.feeCycleType : '—'),
                  InfoRow('Next due', s.nextDueDate.isNotEmpty ? s.nextDueDate : '—'),
                  InfoRow('Last receipt', s.lastReceiptNo.isNotEmpty ? '${s.lastReceiptNo} · ₹${s.lastReceiptAmount}' : '—'),
                  InfoRow('Admission via', admissionSourceLabel(s.admissionSource).isEmpty ? '—' : admissionSourceLabel(s.admissionSource)),
                ]),
              ),
            ),
            const SizedBox(height: AppSpace.s3),
            // Teacher relationship — clickable when a stable teacherId exists.
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: 6),
                leading: Icon(Icons.person_pin_circle_outlined, color: AppColors.adaptive(context, AppColors.primary)),
                title: Text(
                  _detail?.hasAssignedTeacher == true
                      ? (_detail!.hasTeacherName ? _detail!.teacherName : 'Teacher')
                      : 'No teacher assigned',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                subtitle: _detail?.hasTeacherId == true
                    ? Text(_detail!.teacherId, style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted)))
                    : null,
                trailing: _detail?.hasTeacherId == true
                    ? Icon(Icons.chevron_right, color: AppColors.adaptive(context, AppColors.muted))
                    : null,
                onTap: _detail?.hasTeacherId == true
                    ? () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => TeacherProfileScreen(
                          teacherId: _detail!.teacherId,
                          staff: widget.staff,
                        ),
                      ))
                    : null,
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
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.adaptive(context, AppColors.focus)),
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
            if (widget.staff) ...[
              const SizedBox(height: AppSpace.s3),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PackageExtensionScreen(student: s),
                )),
                icon: const Icon(Icons.event_repeat_outlined, size: 18),
                label: const Text('Request package extension'),
              ),
              const SizedBox(height: AppSpace.s3),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LateFeeWaiverScreen(student: s),
                )),
                icon: const Icon(Icons.money_off_outlined, size: 18),
                label: const Text('Request late-fee waiver'),
              ),
              const SizedBox(height: AppSpace.s3),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => InstalmentPlanScreen(student: s),
                )),
                icon: const Icon(Icons.calendar_view_month_outlined, size: 18),
                label: const Text('Request instalment plan'),
              ),
              const SizedBox(height: AppSpace.s3),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TermsScreen(student: s),
                )),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Admission terms'),
              ),
              const SizedBox(height: AppSpace.s3),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PauseMembershipScreen(student: s),
                )),
                icon: Icon(s.status.toUpperCase() == 'PAUSED' ? Icons.play_circle_outline : Icons.pause_circle_outline, size: 18),
                label: Text(s.status.toUpperCase() == 'PAUSED' ? 'Request resume' : 'Request pause'),
              ),
            ],
            if (widget.staff && _hub != null && _hub!.pending.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s3),
              const SectionTitle('Approved payments'),
              for (final d in _hub!.pending)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpace.s3),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.s4),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('₹${d.amount} · ${d.paymentDate}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text(d.draftId, style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
                          ]),
                        ),
                        StatusBadge(d.repairRequired ? 'REPAIR REQUIRED' : d.status),
                      ]),
                      if (d.label.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.s2),
                          child: Text(d.label, style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
                        ),
                      if (d.blockedReason.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.s2),
                          child: Text(d.blockedReason,
                              style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.warnFg))),
                        ),
                      if (d.canFinalise)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.s2),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: AppColors.adaptive(context, AppColors.primary)),
                              onPressed: _busy ? null : () => _staffFinalise(d),
                              icon: const Icon(Icons.receipt_long_outlined, size: 18),
                              label: const Text('Create receipt now'),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
            ],
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
                    leading: Icon(Icons.receipt_long_outlined, color: AppColors.adaptive(context, AppColors.muted)),
                    title: Text(r.receiptNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${r.date} · ${r.mode}${r.excluded ? ' · EXCLUDED' : ''}',
                        style: TextStyle(fontSize: 12, color: AppColors.adaptive(context, AppColors.muted))),
                    trailing: Text(inr(r.amount),
                        style: TextStyle(fontWeight: FontWeight.w800, color: r.excluded ? AppColors.adaptive(context, AppColors.muted) : AppColors.adaptive(context, AppColors.primary))),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}