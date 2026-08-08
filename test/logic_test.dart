// Unit tests for the app's pure business logic. These deliberately avoid
// widgets/plugins (sqflite, ads, etc.) so they run fast and deterministically.

import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/premium_limits.dart';
import 'package:manage_subscription/core/utils/billing.dart';
import 'package:manage_subscription/core/utils/currency.dart';
import 'package:manage_subscription/data/models/subscription.dart';

void main() {
  group('Recurrence factors', () {
    test('monthly-equivalent multipliers', () {
      expect(const Recurrence(1, IntervalUnit.month).monthlyFactor, 1);
      expect(const Recurrence(12, IntervalUnit.month).monthlyFactor,
          closeTo(1 / 12, 1e-9));
      expect(const Recurrence(1, IntervalUnit.week).monthlyFactor,
          closeTo(52 / 12, 1e-9));
    });

    test('custom "every N days" occurs ~30.44/N times a month', () {
      expect(const Recurrence(10, IntervalUnit.day).monthlyFactor,
          closeTo((365.25 / 12) / 10, 1e-9));
    });
  });

  group('Billing date math', () {
    const monthly = Recurrence(1, IntervalUnit.month);

    test('nextPaymentDate advances a past monthly anchor to the future', () {
      final next = Billing.nextPaymentDate(
        DateTime(2026, 1, 15),
        monthly,
        from: DateTime(2026, 3, 20),
      );
      expect(next, DateTime(2026, 4, 15));
    });

    test('custom every-3-days recurrence advances correctly', () {
      final next = Billing.nextPaymentDate(
        DateTime(2026, 3, 1),
        const Recurrence(3, IntervalUnit.day),
        from: DateTime(2026, 3, 8),
      );
      expect(next, DateTime(2026, 3, 10));
    });

    test('daysUntil counts calendar days', () {
      expect(
        Billing.daysUntil(DateTime(2026, 4, 15), from: DateTime(2026, 3, 20)),
        26,
      );
    });

    test('periodProgress is between 0 and 1 mid-cycle', () {
      final p = Billing.periodProgress(
        DateTime(2026, 1, 15),
        monthly,
        from: DateTime(2026, 3, 20),
      );
      expect(p, greaterThan(0));
      expect(p, lessThan(1));
    });

    test('paymentsInRange returns one occurrence per month', () {
      final payments = Billing.paymentsInRange(
        DateTime(2026, 1, 10),
        monthly,
        DateTime(2026, 1, 1),
        DateTime(2026, 3, 31),
      );
      expect(payments, [
        DateTime(2026, 1, 10),
        DateTime(2026, 2, 10),
        DateTime(2026, 3, 10),
      ]);
    });

    test('monthly anchor clamps to the last day of short months', () {
      // Anchored on the 31st, the February occurrence must clamp to the 28th.
      final feb = Billing.paymentsInRange(
        DateTime(2026, 1, 31),
        monthly,
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 28),
      );
      expect(feb.single, DateTime(2026, 2, 28));
    });
  });

  group('Currency conversion', () {
    test('USD converts to JPY at the fixed rate', () {
      expect(CurrencyRates.convert(10, 'USD', 'JPY'), 1550);
    });

    test('same-currency conversion is identity', () {
      expect(CurrencyRates.convert(1234, 'JPY', 'JPY'), 1234);
    });
  });

  group('Subscription cospa & derived money', () {
    Subscription sub({
      double amount = 1200,
      BillingCycle cycle = BillingCycle.monthly,
      double usage = 0,
      String currency = 'JPY',
    }) =>
        Subscription(
          id: 't',
          name: 'Test',
          amount: amount,
          currencyCode: currency,
          cycle: cycle,
          firstPaymentDate: DateTime(2026, 1, 1),
          colorValue: 0xFF000000,
          usageCount: usage,
          createdAt: DateTime(2026, 1, 1),
        );

    test('yearly plan reports a monthly-equivalent amount', () {
      expect(sub(amount: 12000, cycle: BillingCycle.yearly).monthlyAmount,
          closeTo(1000, 1e-9));
    });

    test('costPerUse divides monthly spend by monthly uses', () {
      expect(sub(amount: 1500, usage: 10).costPerUse, 150);
    });

    test('costPerUse is null when usage is not tracked', () {
      expect(sub(usage: 0).costPerUse, isNull);
    });

    test('displayGlyph never throws on empty name/emoji', () {
      expect(sub().copyWith(name: '').displayGlyph, '?');
      expect(sub().copyWith(name: 'Netflix').displayGlyph, 'N');
      expect(sub().copyWith(name: 'Netflix', emoji: '🎬').displayGlyph, '🎬');
    });
  });

  group('PremiumLimits (free-tier gates)', () {
    test('subscription limit blocks the free tier at the cap', () {
      expect(PremiumLimits.canAddSubscription(false, 8), isFalse);
      expect(PremiumLimits.canAddSubscription(false, 7), isTrue);
      expect(PremiumLimits.canAddSubscription(true, 999), isTrue);
    });

    test('premium-only capabilities are gated', () {
      expect(PremiumLimits.canExportCsv(false), isFalse);
      expect(PremiumLimits.canExportCsv(true), isTrue);
      expect(PremiumLimits.canAttachImage(false), isFalse);
      expect(PremiumLimits.canViewAllPeriods(false), isFalse);
    });

    test('free tier: 5 categories / 5 payment methods', () {
      expect(PremiumLimits.canAddCategory(false, 4), isTrue);
      expect(PremiumLimits.canAddCategory(false, 5), isFalse);
      expect(PremiumLimits.canAddPaymentMethod(false, 4), isTrue);
      expect(PremiumLimits.canAddPaymentMethod(false, 5), isFalse);
    });

    test('sorting, theme, and category/method breakdown are free', () {
      expect(PremiumLimits.canAutoSort(false), isTrue);
      expect(PremiumLimits.canChangeTheme(false), isTrue);
      expect(PremiumLimits.canBreakdownByCategoryOrMethod(false), isTrue);
    });

    test('notify-rule limit is unlimited for everyone', () {
      expect(PremiumLimits.notifyRuleLimit(false),
          PremiumLimits.notifyRuleLimit(true));
      expect(PremiumLimits.notifyRuleLimit(false), greaterThan(1));
    });
  });
}
