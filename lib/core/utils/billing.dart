// Billing cycle & date math shared by home, calendar, analytics and history.

enum BillingCycle { monthly, yearly, weekly }

extension BillingCycleX on BillingCycle {
  String get label => switch (this) {
        BillingCycle.monthly => '月',
        BillingCycle.yearly => '年',
        BillingCycle.weekly => '週',
      };

  /// Monthly-equivalent multiplier (a yearly plan costs 1/12 per month).
  double get monthlyFactor => switch (this) {
        BillingCycle.monthly => 1,
        BillingCycle.yearly => 1 / 12,
        BillingCycle.weekly => 52 / 12,
      };

  double get yearlyFactor => monthlyFactor * 12;

  static BillingCycle fromName(String? name) =>
      BillingCycle.values.firstWhere((c) => c.name == name,
          orElse: () => BillingCycle.monthly);
}

class Billing {
  Billing._();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Next occurrence of the billing date on or after [from], starting from the
  /// [anchor] (first payment date) and advancing by the cycle.
  static DateTime nextPaymentDate(
    DateTime anchor,
    BillingCycle cycle, {
    DateTime? from,
  }) {
    final today = _dateOnly(from ?? DateTime.now());
    var next = _dateOnly(anchor);

    if (next.isAfter(today) || next.isAtSameMomentAs(today)) return next;

    switch (cycle) {
      case BillingCycle.weekly:
        final days = today.difference(next).inDays;
        next = next.add(Duration(days: ((days ~/ 7) + 1) * 7));
        while (next.isBefore(today)) {
          next = next.add(const Duration(days: 7));
        }
      case BillingCycle.monthly:
        while (next.isBefore(today)) {
          next = _addMonths(next, 1, anchor.day);
        }
      case BillingCycle.yearly:
        while (next.isBefore(today)) {
          next = _addMonths(next, 12, anchor.day);
        }
    }
    return next;
  }

  /// The payment date of the *current* period (the most recent one on or
  /// before today) — the start of the running progress bar.
  static DateTime currentPeriodStart(
    DateTime anchor,
    BillingCycle cycle, {
    DateTime? from,
  }) {
    final next = nextPaymentDate(anchor, cycle, from: from);
    return previousPaymentDate(next, cycle, anchor.day);
  }

  static DateTime previousPaymentDate(DateTime date, BillingCycle cycle, int anchorDay) {
    switch (cycle) {
      case BillingCycle.weekly:
        return date.subtract(const Duration(days: 7));
      case BillingCycle.monthly:
        return _addMonths(date, -1, anchorDay);
      case BillingCycle.yearly:
        return _addMonths(date, -12, anchorDay);
    }
  }

  static DateTime _addMonths(DateTime d, int months, int anchorDay) {
    final total = d.month - 1 + months;
    final year = d.year + (total ~/ 12) - (total < 0 && total % 12 != 0 ? 1 : 0);
    var month = total % 12;
    if (month < 0) month += 12;
    month += 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, anchorDay.clamp(1, lastDay));
  }

  static int daysUntil(DateTime target, {DateTime? from}) {
    final today = _dateOnly(from ?? DateTime.now());
    return _dateOnly(target).difference(today).inDays;
  }

  /// Fraction (0..1) of the current billing period elapsed — drives the home
  /// progress bar. Near 1.0 = payment is imminent.
  static double periodProgress(DateTime anchor, BillingCycle cycle, {DateTime? from}) {
    final today = _dateOnly(from ?? DateTime.now());
    final start = currentPeriodStart(anchor, cycle, from: from);
    final next = nextPaymentDate(anchor, cycle, from: from);
    final total = next.difference(start).inDays;
    if (total <= 0) return 1;
    final elapsed = today.difference(start).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// All payment dates for a subscription that fall within [start]..[end].
  static List<DateTime> paymentsInRange(
    DateTime anchor,
    BillingCycle cycle,
    DateTime start,
    DateTime end,
  ) {
    final result = <DateTime>[];
    var d = _dateOnly(anchor);
    // Rewind to at or before the range start.
    while (d.isAfter(start)) {
      d = previousPaymentDate(d, cycle, anchor.day);
    }
    // Advance and collect.
    var guard = 0;
    while (d.isBefore(end) || d.isAtSameMomentAs(end)) {
      if (!d.isBefore(start)) result.add(d);
      final next = switch (cycle) {
        BillingCycle.weekly => d.add(const Duration(days: 7)),
        BillingCycle.monthly => _addMonths(d, 1, anchor.day),
        BillingCycle.yearly => _addMonths(d, 12, anchor.day),
      };
      d = next;
      if (++guard > 2000) break;
    }
    return result;
  }
}
