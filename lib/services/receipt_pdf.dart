import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

/// A5 fee receipt rendered from the server's receipt row. The app only lays
/// out figures the server already decided (amount, number, dates); it never
/// computes any of them.
Future<Uint8List> buildReceiptPdf(ReceiptRow r, {bool demo = false}) async {
  final doc = pw.Document();
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-400.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-700.ttf'));
  final theme = pw.ThemeData.withFont(base: regular, bold: bold);

  pw.Widget row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey700)),
          ),
          pw.Expanded(child: pw.Text(value.isEmpty ? '-' : value, style: const pw.TextStyle(fontSize: 11))),
        ]),
      );

  final period = r.feePeriodFrom.isNotEmpty
      ? (r.feePeriodTo.isNotEmpty ? '${r.feePeriodFrom} to ${r.feePeriodTo}' : 'from ${r.feePeriodFrom}')
      : '';

  doc.addPage(
    pw.Page(
      theme: theme,
      pageFormat: pdf.PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(
          child: pw.Column(children: [
            pw.Text('SWAR MANGAL', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Music Academy', style: const pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey700)),
            pw.Text(r.entityId == 'ENT-GOREGAON' ? 'Goregaon' : 'Kandivali',
                style: const pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey700)),
          ]),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: pdf.PdfColors.grey400),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('FEE RECEIPT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text(r.receiptNo, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.SizedBox(height: 12),
        row('Received from', r.student),
        row('Date', r.date),
        row('Payment mode', r.paymentMode.isNotEmpty ? r.paymentMode : r.mode),
        if (r.txnId.isNotEmpty) row('Reference / UTR', r.txnId),
        if (period.isNotEmpty) row('Fee period', period),
        row('Status', r.status),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: pdf.PdfColors.grey500),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Amount received', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Rs ${indianAmount(r.amount)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ]),
        ),
        pw.Spacer(),
        if (demo)
          pw.Text('DEMO - not a real receipt', style: const pw.TextStyle(fontSize: 10, color: pdf.PdfColors.red)),
        pw.Text('This is a computer-generated receipt.',
            style: const pw.TextStyle(fontSize: 9, color: pdf.PdfColors.grey600)),
      ]),
    ),
  );
  return doc.save();
}

/// 184500 -> "1,84,500"; keeps paise when present.
String indianAmount(num value) {
  final whole = value.truncate();
  final paise = ((value - whole) * 100).round();
  var digits = whole.abs().toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  final sign = value < 0 ? '-' : '';
  return paise == 0 ? '$sign$grouped' : '$sign$grouped.${paise.toString().padLeft(2, '0')}';
}

Future<void> showReceiptPdf(Uint8List bytes, String title) async {
  await Printing.layoutPdf(onLayout: (_) async => bytes, name: title);
}
