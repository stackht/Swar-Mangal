import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/sync_manager.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../widgets/anim.dart';
import '../../widgets/atoms.dart';
import 'receipt_detail_screen.dart';

/// Receipt search. Founder: full master search. Staff: branch-isolated.
class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key, required this.staff});
  final bool staff;
  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> with SyncAware
  @override
  Set<String> get syncEntities => { 'receipts', 'payments' };

  @override
  Future<void> reloadFromSync() => _load; with SyncAware
  @override
  Set<String> get syncEntities => { 'receipts', 'payments' };

  @override
  Future<void> reloadFromSync() => _load; {
  final _q = TextEditingController();
  List<ReceiptRow> _rows = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    final auth = context.read<AuthProvider>();
    if (auth.service == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await auth.service!.searchReceipts(
        q: q,
        studentName: q,
        receiptNo: q,
        classCode: widget.staff ? _classFor(auth.branch ?? '') : 'ALL',
      );
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

  String _classFor(String branch) {
    if (branch == 'KANDIVALI') return 'KMC';
    if (branch == 'GOREGAON') return 'GMC';
    return 'ALL';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: SearchField(
          controller: _q,
          hint: 'Receipt no, student name or UTR',
          onChanged: (_) {
            if (_q.text.trim().isEmpty) setState(() => _rows = []);
          },
          trailingIcon: Icons.arrow_forward,
        ),
      ),
      Expanded(
        child: _busy
            ? const SkeletonList(rows: 6)
            : _error != null && _rows.isEmpty
                ? ErrorView(_error!, onRetry: () => _search(_q.text))
                : _rows.isEmpty
                    ? EmptyState(
                        _q.text.trim().isEmpty
                            ? 'Search receipts by number, student or UTR.'
                            : 'No receipts matched.',
                        icon: Icons.receipt_long_outlined)
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: AppSpace.s6),
                        itemCount: _rows.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (c, i) => _row(_rows[i]),
                      ),
      ),
    ]);
  }

  Widget _row(ReceiptRow r) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReceiptDetailScreen(receipt: r),
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
        child: Row(children: [
          Icon(Icons.receipt_long_outlined,
              color: r.excluded ? AppColors.muted : AppColors.primary),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.receiptNo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text('${r.student} · ${r.date}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              Text(r.mode.isNotEmpty ? r.mode : '—',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AmountText(r.amount),
            const SizedBox(height: 2),
            StatusBadge(r.status),
          ]),
        ]),
      ),
    );
  }
}