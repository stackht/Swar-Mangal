import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../services/invoice_pdf.dart';
import '../../widgets/atoms.dart';

/// School-level invoice editor. Fields are class/amount/tenure/date — NO
/// student identity. One primary "Generate PDF" action; one intent key per
/// form prevents duplicate invoices on retry/double-tap.
class InvoiceConfigScreen extends StatefulWidget {
  const InvoiceConfigScreen({super.key, required this.staff});
  final bool staff;
  @override
  State<InvoiceConfigScreen> createState() => _InvoiceConfigScreenState();
}

class _InvoiceConfigScreenState extends State<InvoiceConfigScreen> {
  final _amount = TextEditingController(text: '18000');
  final _class = TextEditingController();
  final _intent = 'SINV-${DateTime.now().microsecondsSinceEpoch}';
  String _tenure = '6 Months';
  String _invoiceDate = '';
  bool _busy = false;
  String? _error;

  static const _tenures = ['1 Month', '3 Months', '6 Months', '12 Months'];

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _invoiceDate = '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _amount.dispose();
    _class.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    final a = InvoiceValidator.amount(_amount.text);
    if (!a.ok) {
      setState(() => _error = a.error);
      return;
    }
    final tErr = InvoiceValidator.tenure(_tenure);
    if (tErr != null) {
      setState(() => _error = tErr);
      return;
    }
    final cErr = InvoiceValidator.className(_class.text);
    if (cErr != null) {
      setState(() => _error = cErr);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final inv = await auth.service!.generateSchoolInvoice(
        className: _class.text.trim(),
        amount: a.amount!,
        tenure: _tenure,
        invoiceDate: _invoiceDate,
        branch: auth.branch ?? 'ALL',
        intentKey: _intent,
      );
      if (!mounted) return;
      final demo = auth.isDemo || inv.demo;
      final bytes = await buildInvoicePdf(inv, demo: demo);
      setState(() => _busy = false);
      await showInvoicePdf(bytes, '${inv.invoiceNo}.pdf');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text('Invoice ${inv.invoiceNo} generated.'
                '${demo ? ' (DEMO — NOT PERSISTED)' : ''}')));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message; // keep entered values; retry uses the same intent key
      });
    } on ApiUnreachable catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('School invoice')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('CLASS',
                      style: AppType.eyebrow.copyWith(color: scheme.onSurfaceVariant)),
                ),
                const SizedBox(height: AppSpace.s2),
                TextFormField(
                  controller: _class,
                  decoration: const InputDecoration(
                    labelText: 'Class name *',
                    hintText: 'e.g. Keyboard',
                    prefixIcon: Icon(Icons.music_note_outlined),
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Invoice amount (INR) *',
                      prefixIcon: Icon(Icons.currency_rupee)),
                ),
                const SizedBox(height: AppSpace.s3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('TENURE',
                      style: AppType.eyebrow.copyWith(color: scheme.onSurfaceVariant)),
                ),
                const SizedBox(height: AppSpace.s2),
                Wrap(
                  spacing: AppSpace.s2,
                  runSpacing: AppSpace.s2,
                  children: _tenures.map((t) {
                    final sel = _tenure == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: sel,
                      onSelected: (_) => setState(() => _tenure = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpace.s3),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: AppColors.muted),
                  title: Text('Invoice date: $_invoiceDate'),
                  trailing: TextButton(
                    onPressed: () async {
                      final f = _invoiceDate.split('-');
                      final d = await showDatePicker(
                        context: context,
                        initialDate: f.length == 3
                            ? DateTime(int.parse(f[0]), int.parse(f[1]), int.parse(f[2]))
                            : DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (d != null) {
                        setState(() => _invoiceDate =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
                      }
                    },
                    child: const Text('Change'),
                  ),
                ),
              ]),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s3),
              child: Card(
                color: AppColors.blockBg,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s3),
                  child: Text(_error!, style: const TextStyle(color: AppColors.blockFg, fontSize: 13)),
                ),
              ),
            ),
          const SizedBox(height: AppSpace.s4),
          LoadingButton(
            label: 'Generate PDF',
            icon: Icons.picture_as_pdf_outlined,
            busy: _busy,
            onPressed: _generate,
          ),
          const SizedBox(height: AppSpace.s3),
          Text(
            'School-level invoice — no student is attached. The backend assigns the number and persists '
            'an immutable snapshot; the app only renders the PDF.',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}