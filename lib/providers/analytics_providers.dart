import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/billing.dart';
import '../core/utils/currency.dart';
import '../data/models/subscription.dart';
import 'settings_provider.dart';
import 'subscription_providers.dart';

enum AnalyticsScope { month, year }

enum AnalyticsAxis { subscription, category, paymentMethod }

extension AnalyticsAxisX on AnalyticsAxis {
  String get label => switch (this) {
        AnalyticsAxis.subscription => 'サブスク別',
        AnalyticsAxis.category => 'カテゴリー別',
        AnalyticsAxis.paymentMethod => '支払い方法別',
      };
  bool get isPremium => this != AnalyticsAxis.subscription;
}

@immutable
class AnalyticsSlice {
  const AnalyticsSlice({
    required this.label,
    required this.color,
    required this.amount,
    required this.groupKey,
    this.nativeLabel,
  });
  final String label;
  final Color color;
  final double amount;

  /// The grouping key this slice represents: a subscription id, a category id,
  /// a payment-method id, or '__none'. Used to drill into the breakdown.
  final String groupKey;

  /// e.g. original "$22.00" when the sub isn't in the main currency.
  final String? nativeLabel;
}

@immutable
class AnalyticsResult {
  const AnalyticsResult({required this.slices, required this.total});
  final List<AnalyticsSlice> slices;
  final double total;
}

@immutable
class AnalyticsQuery {
  const AnalyticsQuery(this.scope, this.axis);
  final AnalyticsScope scope;
  final AnalyticsAxis axis;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsQuery && other.scope == scope && other.axis == axis;
  @override
  int get hashCode => Object.hash(scope, axis);
}

/// Aggregates active subscriptions into donut slices for the given scope+axis,
/// all converted to the user's main currency.
final analyticsProvider =
    Provider.family<AnalyticsResult, AnalyticsQuery>((ref, q) {
  final subs = (ref.watch(subscriptionsProvider).valueOrNull ?? const [])
      .where((s) => !s.isPaused)
      .toList();
  final settings = ref.watch(settingsProvider);
  final cats = ref.watch(categoriesMapProvider);
  final methods = ref.watch(paymentMethodsMapProvider);
  final currency = settings.mainCurrency;

  double amountOf(Subscription s) => q.scope == AnalyticsScope.month
      ? s.monthlyAmountIn(currency)
      : s.yearlyAmountIn(currency);

  final result = <String, ({String label, Color color, double amount, String? native})>{};

  for (var i = 0; i < subs.length; i++) {
    final s = subs[i];
    final value = amountOf(s);
    switch (q.axis) {
      case AnalyticsAxis.subscription:
        final native = s.currency != currency
            ? CurrencyLabel.native(s, q.scope)
            : null;
        result[s.id] = (label: s.name, color: s.color, amount: value, native: native);
      case AnalyticsAxis.category:
        final c = cats[s.categoryId];
        final key = c?.id ?? '__none';
        final prev = result[key];
        result[key] = (
          label: c?.name ?? '未分類',
          color: c?.color ?? AppColors.textMuted,
          amount: (prev?.amount ?? 0) + value,
          native: null,
        );
      case AnalyticsAxis.paymentMethod:
        final m = methods[s.paymentMethodId];
        final key = m?.id ?? '__none';
        final prev = result[key];
        result[key] = (
          label: m?.name ?? '未設定',
          color: m?.color ?? AppColors.textMuted,
          amount: (prev?.amount ?? 0) + value,
          native: null,
        );
    }
  }

  // Each slice uses the item's own set color (subscription/category/payment
  // method color) — adjacent slices may share a color and that's accepted.
  final slices = result.entries
      .map((e) => AnalyticsSlice(
          label: e.value.label,
          color: e.value.color,
          amount: e.value.amount,
          groupKey: e.key,
          nativeLabel: e.value.native))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final total = slices.fold<double>(0, (sum, s) => sum + s.amount);
  return AnalyticsResult(slices: slices, total: total);
});

@immutable
class AnalyticsMemberQuery {
  const AnalyticsMemberQuery(this.axis, this.groupKey);
  final AnalyticsAxis axis;
  final String groupKey;
  @override
  bool operator ==(Object other) =>
      other is AnalyticsMemberQuery &&
      other.axis == axis &&
      other.groupKey == groupKey;
  @override
  int get hashCode => Object.hash(axis, groupKey);
}

/// The active subscriptions that make up one analytics slice — powers the
/// long-press breakdown.
final analyticsMembersProvider =
    Provider.family<List<Subscription>, AnalyticsMemberQuery>((ref, q) {
  final subs = (ref.watch(subscriptionsProvider).valueOrNull ?? const [])
      .where((s) => !s.isPaused);
  bool matches(Subscription s) {
    switch (q.axis) {
      case AnalyticsAxis.subscription:
        return s.id == q.groupKey;
      case AnalyticsAxis.category:
        return (s.categoryId ?? '__none') == q.groupKey;
      case AnalyticsAxis.paymentMethod:
        return (s.paymentMethodId ?? '__none') == q.groupKey;
    }
  }

  final currency = ref.watch(settingsProvider).mainCurrency;
  final list = subs.where(matches).toList()
    ..sort((a, b) =>
        b.monthlyAmountIn(currency).compareTo(a.monthlyAmountIn(currency)));
  return list;
});

class CurrencyLabel {
  static String native(Subscription s, AnalyticsScope scope) {
    final f = s.currency;
    final amt = scope == AnalyticsScope.month ? s.monthlyAmount : s.yearlyAmount;
    return '${f.symbol}${amt.toStringAsFixed(f.decimals)}';
  }
}

// ── History (bar chart) ─────────────────────────────────────────────────────
@immutable
class MonthlySpend {
  const MonthlySpend(this.month, this.amount, this.paid);
  final int month; // 1..12

  /// Full amount scheduled to be billed that month (the gray bar height).
  final double amount;

  /// Amount already billed (payment date on or before today) — the colored,
  /// stacked portion within the gray bar.
  final double paid;
}

/// Scheduled ("amount") and already-paid ("paid") spend per month for [year],
/// in the main currency — drives the stacked history bar chart.
final monthlyHistoryProvider =
    Provider.family<List<MonthlySpend>, int>((ref, year) {
  final subs = ref.watch(subscriptionsProvider).valueOrNull ?? const [];
  final currency = ref.watch(settingsProvider).mainCurrency;
  final today = DateTime.now();

  final planned = List<double>.filled(12, 0);
  final paid = List<double>.filled(12, 0);
  for (final s in subs) {
    if (s.isPaused) continue;
    final amount = s.amountIn(currency);
    for (var m = 1; m <= 12; m++) {
      final start = DateTime(year, m, 1);
      final end = DateTime(year, m + 1, 0);
      final payments =
          Billing.paymentsInRange(s.firstPaymentDate, s.recurrence, start, end);
      for (final d in payments) {
        planned[m - 1] += amount;
        // "Paid" = the payment date has already passed (or is today).
        if (!d.isAfter(today)) paid[m - 1] += amount;
      }
    }
  }
  return [for (var m = 1; m <= 12; m++) MonthlySpend(m, planned[m - 1], paid[m - 1])];
});

/// Subscriptions already billed within a specific month (for the history detail
/// list). Future-dated payments are excluded — only payments whose date has
/// already arrived are shown.
final monthPaymentsProvider =
    Provider.family<List<({Subscription sub, DateTime date})>, DateTime>(
        (ref, month) {
  final subs = ref.watch(subscriptionsProvider).valueOrNull ?? const [];
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  final today = DateTime.now();
  final rows = <({Subscription sub, DateTime date})>[];
  for (final s in subs) {
    if (s.isPaused) continue;
    for (final d
        in Billing.paymentsInRange(s.firstPaymentDate, s.recurrence, start, end)) {
      if (d.isAfter(today)) continue; // hide not-yet-billed payments
      rows.add((sub: s, date: d));
    }
  }
  rows.sort((a, b) => a.date.compareTo(b.date));
  return rows;
});

@immutable
class YearSpend {
  const YearSpend(this.year, this.amount);
  final int year;
  final double amount;
}

/// Total billed spend per year for a window ending at [q.endYear] and spanning
/// [q.count] years — drives the yearly history bar chart.
final yearlyHistoryProvider =
    Provider.family<List<YearSpend>, ({int endYear, int count})>((ref, q) {
  final subs = ref.watch(subscriptionsProvider).valueOrNull ?? const [];
  final currency = ref.watch(settingsProvider).mainCurrency;
  final result = <YearSpend>[];
  for (var y = q.endYear - q.count + 1; y <= q.endYear; y++) {
    double total = 0;
    for (final s in subs) {
      if (s.isPaused) continue;
      final payments = Billing.paymentsInRange(
          s.firstPaymentDate, s.recurrence, DateTime(y, 1, 1), DateTime(y, 12, 31));
      total += payments.length * s.amountIn(currency);
    }
    result.add(YearSpend(y, total));
  }
  return result;
});

/// Per-subscription total for a whole [year] (for the yearly detail list).
final yearSubscriptionTotalsProvider =
    Provider.family<List<({Subscription sub, int count, double total})>, int>(
        (ref, year) {
  final subs = ref.watch(subscriptionsProvider).valueOrNull ?? const [];
  final currency = ref.watch(settingsProvider).mainCurrency;
  final rows = <({Subscription sub, int count, double total})>[];
  for (final s in subs) {
    if (s.isPaused) continue;
    final payments = Billing.paymentsInRange(
        s.firstPaymentDate, s.recurrence, DateTime(year, 1, 1), DateTime(year, 12, 31));
    if (payments.isEmpty) continue;
    rows.add((
      sub: s,
      count: payments.length,
      total: payments.length * s.amountIn(currency),
    ));
  }
  rows.sort((a, b) => b.total.compareTo(a.total));
  return rows;
});
