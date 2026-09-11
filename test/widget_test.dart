import 'package:flutter_test/flutter_test.dart';
import 'package:academyos/models/models.dart';
import 'package:academyos/widgets/atoms.dart';

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
}