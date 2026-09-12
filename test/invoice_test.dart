import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swar_mangal/models/models.dart';
import 'package:swar_mangal/services/demo_api.dart';
import 'package:swar_mangal/services/invoice_pdf.dart';

Map<String, dynamic> _map(dynamic v) => v as Map<String, dynamic>;

void main() {
  group('SchoolInvoice.fromApi', () {
    test('parses demo generation snapshot', () async {
      final b = _map(await DemoApiClient()
          .call('api_generateSchoolInvoice', {'studentId': 'STU-55DCD622', 'amount': 18000, 'tenure': '6 Months'}));
      expect(b['demo'], true);
      final inv = SchoolInvoice.fromApi(b);
      expect(inv.invoiceNo, startsWith('INV-DEMO'));
      expect(inv.amount, 18000);
      expect(inv.tenure, '6 Months');
      expect(inv.owner1.name, isNotEmpty);
      expect(inv.owner2.name, isNotEmpty);
      expect(inv.studentName, isNotEmpty);
    });

    test('class name falls back to course then dash, never fabricated', () {
      final withCourse = SchoolInvoice.fromApi({
        'invoiceNo': 'N', 'invoiceDate': '2026-01-01',
        'studentId': 'S1', 'studentName': 'A', 'course': 'Piano', 'amount': 1, 'tenure': '1M',
      });
      expect(withCourse.displayClassName, 'Piano');
      final blank = SchoolInvoice.fromApi({
        'invoiceNo': 'N', 'invoiceDate': '2026-01-01',
        'studentId': 'S1', 'studentName': 'A', 'amount': 1, 'tenure': '1M',
      });
      expect(blank.displayClassName, '—');
    });
  });

  group('InvoiceSummary.fromApi', () {
    test('parses history rows', () {
      final s = InvoiceSummary.fromApi({
        'invoiceNo': 'INV-001', 'invoiceDate': '2026-06-10', 'tenure': '3 Months', 'amount': 9000, 'invoiceId': 'I1',
      });
      expect(s.invoiceNo, 'INV-001');
      expect(s.tenure, '3 Months');
      expect(s.amount, 9000);
    });
  });

  group('InvoiceValidator', () {
    test('zero rejected', () {
      final v = InvoiceValidator.amount('0');
      expect(v.ok, false);
      expect(v.error, contains('greater than zero'));
    });
    test('valid positive accepted', () {
      final v = InvoiceValidator.amount('18000');
      expect(v.ok, true);
      expect(v.amount, 18000);
    });
    test('comma-formatted accepted', () {
      final v = InvoiceValidator.amount('18,000');
      expect(v.ok, true);
      expect(v.amount, 18000);
    });
    test('negative rejected', () {
      expect(InvoiceValidator.amount('-5').ok, false);
    });
    test('non-numeric rejected', () {
      expect(InvoiceValidator.amount('abc').ok, false);
    });
    test('tenure required', () {
      expect(InvoiceValidator.tenure(''), isNotNull);
      expect(InvoiceValidator.tenure('6 Months'), isNull);
    });
  });

  group('PDF generation', () {
    test('produces a real valid A4 PDF (header + size)', () async {
      final inv = SchoolInvoice.fromApi(_map(await DemoApiClient()
          .call('api_generateSchoolInvoice', {'studentId': 'STU-55DCD622', 'amount': 18000, 'tenure': '6 Months'})));
      final bytes = await buildInvoicePdf(inv, demo: true);
      expect(bytes.length, greaterThan(1000));
      expect(inv.demo, true);
      // %PDF header — a genuine PDF document, never an HTML/PNG stand-in.
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('renders brand + identity for any snapshot (no crash, size sane)', () async {
      final inv = SchoolInvoice.fromApi({
        'invoiceNo': 'INV-TEST-7', 'invoiceDate': '2026-09-12',
        'studentId': 'STU-1', 'studentName': 'Aarav Mehta', 'className': 'Piano',
        'teacherName': 'Rahul Joshi', 'branch': 'GOREGAON', 'amount': 18000,
        'tenure': '6 Months',
        'owner1': {'name': 'Sharvil Vaidya', 'id': 'O1', 'signatureUrl': ''},
        'owner2': {'name': 'Piyush Kashyap', 'id': 'O2', 'signatureUrl': ''},
      });
      final bytes = await buildInvoicePdf(inv, demo: false);
      expect(bytes.length, greaterThan(1000));
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('Demo listStudentInvoices + detail', () {
    late DemoApiClient d;
    setUp(() => d = DemoApiClient());
    test('history returns snapshot rows', () async {
      final b = _map(await d.call('api_listStudentInvoices', {'studentId': 'STU-55DCD622'}));
      expect(b['invoices'], isNotEmpty);
      final s = InvoiceSummary.fromApi((b['invoices'] as List).cast<Map<String, dynamic>>().first);
      expect(s.invoiceNo, isNotEmpty);
    });
    test('invoice detail returns an immutable snapshot', () async {
      final b = _map(await d.call('api_getStudentInvoice', {'invoiceId': 'SINV-DEMO-1'}));
      final inv = SchoolInvoice.fromApi(b['invoice'] as Map<String, dynamic>);
      expect(inv.invoiceNo, 'INV-DEMO-98000');
      expect(inv.owner2.name, isNotEmpty);
    });
  });
}