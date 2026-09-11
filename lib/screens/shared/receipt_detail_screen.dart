import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/atoms.dart';

/// Receipt detail — full row information plus the record status verdict.
class ReceiptDetailScreen extends StatelessWidget {
  const ReceiptDetailScreen({super.key, required this.receipt});
  final ReceiptRow receipt;

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return Scaffold(
      appBar: AppBar(title: Text(r.receiptNo)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s4),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(children: [
                AmountText(r.amount),
                const SizedBox(height: AppSpace.s2),
                Text(r.student, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: AppSpace.s2),
                Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
                  StatusBadge(r.status),
                  if (r.excluded) const StatusBadge('EXCLUDED FROM ACCOUNTS'),
                ]),
              ]),
            ),
          ),
          const SectionTitle('Details'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(children: [
                InfoRow('Receipt no', r.receiptNo),
                InfoRow('Date', r.date),
                InfoRow('Student', r.student),
                InfoRow('Mode', r.mode.isEmpty ? '—' : r.mode),
                InfoRow('Entity', r.entityId.isEmpty ? '—' : r.entityId),
                InfoRow('Fee period', r.feePeriodFrom.isNotEmpty
                    ? '${r.feePeriodFrom} → ${r.feePeriodTo}'
                    : '—'),
              ]),
            ),
          ),
          const SectionTitle('Actions'),
          Row(children: [
            if (r.pdfUrl.isNotEmpty)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(r.pdfUrl.isEmpty ? 'PDF pending' : 'Open PDF'),
                ),
              )
            else
              const Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpace.s3),
                    child: Text('PDF URL not captured on this receipt.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: AppSpace.s3),
          const Text(
            'PDF opening is not enabled on the mobile device build. The link is '
            'shown for verification only.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}