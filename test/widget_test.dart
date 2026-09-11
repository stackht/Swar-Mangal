import 'package:flutter_test/flutter_test.dart';
import 'package:swar_mangal/models/models.dart';
import 'package:swar_mangal/widgets/atoms.dart';

void main() {
  test('INR formatting', () {
    expect(inr(0), '₹0');
    expect(inr(100), '₹100');
    expect(inr(1234), '₹1,234');
    expect(inr(1234567), '₹12,34,567');
    expect(inr(-50), '-₹50');
    expect(inr(49999), '₹49,999');
    expect(inr(100000), '₹1,00,000');
  });

  test('Student.fromApi handles missing fields', () {
    final s = Student.fromApi({});
    expect(s.studentId, '');
    expect(s.studentName, '');
    expect(s.feeDueDay, '');
  });

  test('ReceiptRow.fromApi parses amounts', () {
    final r = ReceiptRow.fromApi({'amount': 5000, 'receiptNo': 'R-001'});
    expect(r.amount, 5000);
    expect(r.receiptNo, 'R-001');
    expect(r.excluded, false);
  });

  test('StatusBadge paints known statuses', () {
    final p = StatusBadge.paint('OVERDUE');
    expect(p.label, contains('OVERDUE'));
  });

  test('PaymentDraftRow parses approve/finalise queue', () {
    final r = PaymentDraftRow.fromApi({
      'draftId': 'PDRAFT-1',
      'status': 'APPROVED',
      'studentName': 'Aarav',
      'amount': '5000',
      'projectedNextDueDate': '2026-10-05',
    });
    expect(r.approved, true);
    expect(r.draftId, 'PDRAFT-1');
    expect(r.projectNextDueDate, '2026-10-05');
  });

  test('StaffHub parses pending finalise drafts', () {
    final b = <String, dynamic>{
      'profile': {'studentId': 'STU-1', 'studentName': 'Diya', 'feeStatus': 'paid'},
      'fees': {'total': 15400, 'rows': []},
      'pending': {
        'rows': [
          {
            'draftId': 'PDRAFT-FIN-1',
            'amount': '12000',
            'approvalAuthority': 'FOUNDER',
            'approvedBy': 'sharvil@demo',
            'founderDecision': true,
            'label': 'Approved',
            'repairRequired': false,
            'status': 'APPROVED',
            'canFinalise': true,
            'blockedReason': '',
          }
        ]
      },
    };
    final hub = StaffHub.fromApi(b);
    expect(hub.pending.length, 1);
    expect(hub.pending.first.canFinalise, true);
    expect(hub.feesTotal, '15400');
  });
}