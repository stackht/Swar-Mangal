import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/atoms.dart';

/// Fee collection.
/// founder: `api_addFeePayment` — real receipt, locked + countered + audited.
/// staff:   `api_staff_prepareReceiptDraft` — a draft that self-serves when
///          routine or waits for founder approval otherwise.
class FeeCollectionScreen extends StatefulWidget {
  const FeeCollectionScreen({super.key, required this.staff, this.prefill});
  final bool staff;
  final Student? prefill;
  @override
  State<FeeCollectionScreen> createState() => _FeeCollectionScreenState();
}

class _FeeCollectionScreenState extends State<FeeCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _txn = TextEditingController();
  final _dueDate = TextEditingController();
  final _feeFrom = TextEditingController();
  final _feeTo = TextEditingController();
  final _notes = TextEditingController();
  Student? _student;
  String _mode = 'Cash';
  bool _busy = false;
  String? _result;
  Map<String, dynamic>? _resData;
  List<String> _paymentModes = const ['Cash', 'Online'];

  @override
  void initState() {
    super.initState();
    final boot = context.read<AuthProvider>().boot;
    if (boot?.paymentModes.isNotEmpty == true) _paymentModes = boot!.paymentModes;
    _student = widget.prefill;
    if (_student != null) {
      _dueDate.text = _student!.nextDueDate;
    }
  }

  @override
  void dispose() {
    for (final c in [_amount, _txn, _dueDate, _feeFrom, _feeTo, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _result = null;
      _resData = null;
    });
    try {
      final amount = num.tryParse(_amount.text.trim()) ?? 0;
      final m = widget.staff
          ? {
              'studentId': _student?.studentId ?? '',
              'branch': auth.branch ?? '',
              'amountPaise': (amount * 100).round(),
              'paymentDate': _dueDate.text.trim().isEmpty ? _today() : _dueDate.text.trim(),
              'packageStartDate': _feeFrom.text.trim(),
              'paymentMode': _mode,
              'paymentReference': _txn.text.trim(),
              'receivingAccountRef': _accountFor(_mode),
              'notes': _notes.text.trim(),
              'physicalReceiptNo': '',
              'monthsPaid': '1',
            }
          : {
              'studentId': _student?.studentId ?? '',
              'studentName': _student?.studentName ?? '',
              'phone': _student?.phone ?? '',
              'classCode': _student?.classCode ?? '',
              'paymentMode': _mode,
              'mode': _accountFor(_mode),
              'account': _accountFor(_mode),
              'txnId': _mode == 'Cash' ? '' : _txn.text.trim(),
              'amount': amount,
              'baseAmount': amount,
              'dueDate': _dueDate.text.trim(),
              'feeFrom': _feeFrom.text.trim(),
              'feeTo': _feeTo.text.trim(),
              'requestId': '${DateTime.now().millisecondsSinceEpoch}-${_student?.studentId ?? ''}',
            };
      final r = widget.staff
          ? await auth.service!.raw('api_staff_prepareReceiptDraft', m)
          : await auth.service!.addFeePayment(m);
      final data = r as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _busy = false;
        _resData = data;
        _result = _message(data);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = e.message;
      });
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = e.message;
      });
    }
  }

  String _message(Map<String, dynamic> d) {
    if (d['ok'] == true) {
      final no = d['receiptNo'] ?? d['draftId'] ?? '';
      final routine = d['routine'] is Map && d['routine']['selfServe'] == true;
      if (widget.staff) {
        return routine
            ? 'Receipt ${d['receiptNo']} created (routine).'
            : 'Payment draft ${d['draftId']} saved — founder approval pending.'
                '${d['paymentPrompt'] == true ? ' Record the payment now → receipt.' : ''}';
      }
      return 'Receipt ${no != '' ? no : ''} created and recorded.';
    }
    return (d['error'] ?? 'Could not record fee.').toString();
  }

  String _accountFor(String mode) {
    if (mode.toUpperCase().contains('CASH')) return 'Cash';
    if (mode.toUpperCase().contains('UPI')) return 'UPI';
    return mode;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.s4),
      children: [
        if (_student == null)
          _studentPicker()
        else
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: AppColors.primary),
              title: Text(_student!.studentName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${_student!.studentId} · ${_student!.classCode} · ${_student!.phone}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _student = null),
              ),
            ),
          ),
        const SizedBox(height: AppSpace.s3),
        Form(
          key: _formKey,
          child: Column(children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(children: [
                  SegmentedButton<String>(
                    segments: _paymentModes
                        .map((p) => ButtonSegment(
                              value: p,
                              label: Text(p),
                              icon: Icon(Icons.circle,
                                  size: 12,
                                  color: p.toUpperCase().contains('CASH') ? AppColors.okFg : AppColors.focus),
                            ))
                        .toList(),
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                  const SizedBox(height: AppSpace.s3),
                  TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                    validator: (v) {
                      final n = num.tryParse(v ?? '');
                      return (n == null || n <= 0) ? 'Enter a valid amount' : null;
                    },
                  ),
                  const SizedBox(height: AppSpace.s3),
                  TextFormField(
                    controller: _dueDate,
                    readOnly: true,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (d != null) {
                        _dueDate.text =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Payment date', prefixIcon: Icon(Icons.event_outlined)),
                  ),
                  const SizedBox(height: AppSpace.s3),
                  if (_mode.toUpperCase().contains('CASH'))
                    SizedBox.shrink()
                  else ...[
                    TextFormField(
                      controller: _txn,
                      decoration: const InputDecoration(
                          labelText: 'Transaction ID / UTR', prefixIcon: Icon(Icons.tag)),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Non-cash payments need a reference'
                          : null,
                    ),
                    const SizedBox(height: AppSpace.s3),
                  ],
                  TextFormField(
                    controller: _feeFrom,
                    readOnly: true,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (d != null) {
                        _feeFrom.text =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                        _feeTo.text =
                            '${d.year}-${(d.month + 1).clamp(1, 12)}-${d.day.toString().padLeft(2, '0')}';
                      }
                    },
                    decoration: InputDecoration(
                        labelText: widget.staff ? 'Package / fee start date' : 'Fee period from',
                        prefixIcon: const Icon(Icons.date_range_outlined)),
                  ),
                  if (!widget.staff) ...[
                    const SizedBox(height: AppSpace.s3),
                    TextFormField(
                      controller: _feeTo,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Fee period to', prefixIcon: Icon(Icons.date_range_outlined)),
                    ),
                  ],
                  const SizedBox(height: AppSpace.s3),
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  ),
                ]),
              ),
            ),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s3),
                child: Container(
                  padding: const EdgeInsets.all(AppSpace.s3),
                  decoration: BoxDecoration(
                    color: _messageIsOk(_resData) ? AppColors.okBg : AppColors.blockBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(_messageIsOk(_resData) ? Icons.check_circle_outline : Icons.error_outline,
                        size: 18, color: _messageIsOk(_resData) ? AppColors.okFg : AppColors.blockFg),
                    const SizedBox(width: AppSpace.s2),
                    Expanded(child: Text(_result!, style: const TextStyle(fontSize: 13))),
                  ]),
                ),
              ),
            const SizedBox(height: AppSpace.s4),
            LoadingButton(
              label: widget.staff ? 'Submit payment draft' : 'Record receipt',
              icon: Icons.payments,
              busy: _busy,
              onPressed: _student == null ? null : _submit,
            ),
          ]),
        ),
      ],
    );
  }

  bool _messageIsOk(Map<String, dynamic>? d) => d?['ok'] == true;

  Widget _studentPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(children: [
          const Text('No student selected',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: AppSpace.s2),
          const Text('Open a student profile and tap "Collect / record fee", or search here.',
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: AppSpace.s3),
          FilledButton.icon(
            onPressed: () async {
              final picked = await Navigator.of(context).push<Student>(
                MaterialPageRoute(builder: (_) => _PickerScreen(staff: widget.staff)),
              );
              if (picked != null && mounted) {
                setState(() => _student = picked);
              }
            },
            icon: const Icon(Icons.person_search),
            label: const Text('Pick student'),
          ),
        ]),
      ),
    );
  }
}

class _PickerScreen extends StatefulWidget {
  const _PickerScreen({required this.staff});
  final bool staff;
  @override
  State<_PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<_PickerScreen> {
  final _q = TextEditingController();
  List<Student>? _rows;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() => _busy = true);
    try {
      final rows = widget.staff
          ? await auth.service!.staffSearchStudents(q, branch: auth.branch ?? 'ALL')
          : await auth.service!.searchStudents(q);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick student')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: SearchField(controller: _q, hint: 'Name or phone', onChanged: _search),
        ),
        Expanded(
          child: _busy
              ? const Center(child: CircularProgressIndicator())
              : (_rows == null || _rows!.isEmpty)
                  ? const EmptyState('No students matched')
                  : ListView.separated(
                      itemCount: _rows!.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final s = _rows![i];
                        return ListTile(
                          title: Text(s.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${s.studentId} · ${s.classCode} · ${s.phone}'),
                          onTap: () => Navigator.of(context).pop(s),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}