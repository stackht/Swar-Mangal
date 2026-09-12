import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../services/invoice_pdf.dart';
import '../../widgets/atoms.dart';

/// One stored invoice snapshot. Read-only — issuing is immutable. Open / share
/// re-renders from the snapshot, never from the student's current profile.
class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId, required this.staff});
  final String invoiceId;
  final bool staff;
  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  SchoolInvoice? _inv;
  String? _error;
  bool _busy = true;
  bool _pdfBusy = false;

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
      final inv = await auth.service!.getStudentInvoice(
        widget.invoiceId,
        branch: auth.branch ?? 'ALL',
      );
      if (!mounted) return;
      setState(() {
        _inv = inv;
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

  Future<void> _openPdf() async {
    final inv = _inv;
    if (inv == null || _pdfBusy) return;
    setState(() => _pdfBusy = true);
    final bytes = await buildInvoicePdf(inv, demo: inv.demo);
    await showInvoicePdf(bytes, '${inv.invoiceNo}.pdf');
    if (mounted) setState(() => _pdfBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: Padding(padding: const EdgeInsets.all(AppSpace.s4), child: ErrorView(_error!, onRetry: _load)),
      );
    }
    final inv = _inv!;
    return Scaffold(
      appBar: AppBar(title: Text(inv.invoiceNo)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(children: [
                const Text('SCHOOL INVOICE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: AppSpace.s2),
                AmountText(inv.amount),
                const SizedBox(height: AppSpace.s2),
                StatusBadge(inv.demo ? 'DEMO' : 'ISSUED'),
              ]),
            ),
          ),
          const SectionTitle('Billed to'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(children: [
                InfoRow('Student', inv.studentName),
                InfoRow('Student ID', inv.studentId),
                InfoRow('Class', inv.displayClassName),
                InfoRow('Course', inv.course.isNotEmpty ? inv.course : '—'),
                InfoRow('Teacher', inv.teacherName.isNotEmpty ? inv.teacherName : '—'),
                InfoRow('Branch', inv.branch.isNotEmpty ? inv.branch : '—'),
                InfoRow('Invoice date', inv.invoiceDate.isNotEmpty ? inv.invoiceDate : '—'),
              ]),
            ),
          ),
          const SectionTitle('Fee'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(children: [
                InfoRow('Description', 'Music Classes'),
                InfoRow('Tenure', inv.tenure),
                InfoRow('Amount', inr(inv.amount), money: true),
              ]),
            ),
          ),
          const SectionTitle('Owners'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Row(children: [
                Expanded(child: _owner(inv.owner1)),
                Expanded(child: _owner(inv.owner2)),
              ]),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          FilledButton.icon(
            onPressed: _pdfBusy ? null : _openPdf,
            icon: _pdfBusy
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Open / Share PDF'),
          ),
          const SizedBox(height: AppSpace.s3),
          Text(
            'This view is a stored snapshot — edited student data is never used to re-render an '
            'issued invoice. Issued invoices are immutable.',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _owner(InvoiceOwner o) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(o.name.isNotEmpty ? o.name : 'Owner', style: const TextStyle(fontWeight: FontWeight.w700)),
        if (o.title.isNotEmpty)
          Text(o.title, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]);
}