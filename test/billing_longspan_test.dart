import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/utils/billing.dart';

void main() {
  // Regression: a short cycle anchored far in the past used to hit the 5000
  // iteration guard and return wrong dates / miss payments. It must now compute
  // correctly via fast-forward.
  final from = DateTime(2026, 8, 6);
  final anchor2000 = DateTime(2000, 1, 1);

  test('daily cycle anchored in 2000 → next payment is today', () {
    final next = Billing.nextPaymentDate(
        anchor2000, const Recurrence(1, IntervalUnit.day),
        from: from);
    expect(next, from);
  });

  test('weekly cycle anchored in 2000 → next payment within 7 days', () {
    final next = Billing.nextPaymentDate(
        anchor2000, const Recurrence(1, IntervalUnit.week),
        from: from);
    expect(next.isBefore(from), isFalse);
    expect(next.difference(from).inDays, lessThan(7));
  });

  test('paymentsInRange counts every daily payment over a month, no truncation',
      () {
    final list = Billing.paymentsInRange(
      anchor2000,
      const Recurrence(1, IntervalUnit.day),
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );
    expect(list.length, 31); // one per day in August
  });

  test('every-3-days over a decade still lands correctly', () {
    final next = Billing.nextPaymentDate(
        anchor2000, const Recurrence(3, IntervalUnit.day),
        from: from);
    expect(next.isBefore(from), isFalse);
    expect(next.difference(from).inDays, lessThan(3));
  });
}
