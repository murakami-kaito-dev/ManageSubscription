import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/utils/billing.dart';
import 'package:manage_subscription/data/models/notify_rule.dart';
import 'package:manage_subscription/data/models/subscription.dart';
import 'package:manage_subscription/data/models/reminder_fire.dart';

Subscription sub({
  required String id,
  required DateTime firstPayment,
  List<NotifyRule> rules = const [NotifyRule(daysBefore: 0, hour: 9)],
  bool paused = false,
}) =>
    Subscription(
      id: id,
      name: id,
      amount: 1000,
      currencyCode: 'JPY',
      cycle: BillingCycle.monthly,
      firstPaymentDate: firstPayment,
      colorValue: 0xFF000000,
      notifyRules: rules,
      isPaused: paused,
      createdAt: DateTime(2020),
    );

void main() {
  final now = DateTime.now();

  test('includes a future reminder and computes fireAt = due - daysBefore@time',
      () {
    // Due ~1 year out so nextPaymentDate == the anchor (a clean future date).
    final due = DateTime(now.year + 1, 6, 15);
    final s = sub(
        id: 'A',
        firstPayment: due,
        rules: const [NotifyRule(daysBefore: 2, hour: 8, minute: 30)]);

    final fires = computeUpcomingReminders([s], now);

    expect(fires, hasLength(1));
    expect(fires.first.fireAt, DateTime(now.year + 1, 6, 13, 8, 30));
    expect(fires.first.due, due);
  });

  test('excludes paused subscriptions', () {
    final s = sub(
        id: 'P',
        firstPayment: DateTime(now.year + 1, 1, 10),
        paused: true);
    expect(computeUpcomingReminders([s], now), isEmpty);
  });

  test('excludes reminders whose fire-time is already in the past', () {
    // Anchor a year in the PAST → nextPaymentDate rolls forward, but craft a
    // rule far enough back that its fire-time is before now: use a due today-ish
    // with a large daysBefore.
    final s = sub(
        id: 'Past',
        firstPayment: DateTime(now.year - 1, 1, 1),
        rules: const [NotifyRule(daysBefore: 3650, hour: 0)]);
    expect(computeUpcomingReminders([s], now), isEmpty);
  });

  test('sorts soonest first', () {
    final later = sub(id: 'later', firstPayment: DateTime(now.year + 1, 12, 1));
    final sooner = sub(id: 'sooner', firstPayment: DateTime(now.year + 1, 1, 1));
    final fires = computeUpcomingReminders([later, sooner], now);
    expect(fires.map((f) => f.sub.id).toList(), ['sooner', 'later']);
  });

  test('interleaves multiple rules across subscriptions chronologically', () {
    // The iOS icon-badge numbers are assigned from this global order
    // (1st fire → badge 1, 2nd → 2, …), so rules of different subscriptions
    // must interleave by fire-time, not group by subscription.
    final a = sub(
        id: 'A',
        firstPayment: DateTime(now.year + 1, 6, 10),
        rules: const [
          NotifyRule(daysBefore: 7, hour: 9), // 6/3
          NotifyRule(daysBefore: 0, hour: 9), // 6/10
        ]);
    final b = sub(
        id: 'B',
        firstPayment: DateTime(now.year + 1, 6, 5),
        rules: const [NotifyRule(daysBefore: 0, hour: 9)]); // 6/5
    final fires = computeUpcomingReminders([a, b], now);
    expect(fires.map((f) => f.sub.id).toList(), ['A', 'B', 'A']);
  });
}
