// Billing cycle & date math shared by home, calendar, analytics and history.

/// The preset cycle chosen in the form. [custom] uses a free interval
/// (every N days / weeks / months) stored on the subscription.
enum BillingCycle { monthly, yearly, weekly, custom }

extension BillingCycleX on BillingCycle {
  static BillingCycle fromName(String? name) =>
      BillingCycle.values.firstWhere((c) => c.name == name,
          orElse: () => BillingCycle.monthly);
}

/// The unit a custom interval is measured in.
enum IntervalUnit { day, week, month }

extension IntervalUnitX on IntervalUnit {
  /// Short suffix for compact labels ("3日", "2週", "6ヶ月").
  String get shortLabel => switch (this) {
        IntervalUnit.day => '日',
        IntervalUnit.week => '週',
        IntervalUnit.month => 'ヶ月',
      };

  /// "◯日ごと" style noun used in pickers.
  String get everyLabel => switch (this) {
        IntervalUnit.day => '日ごと',
        IntervalUnit.week => '週間ごと',
        IntervalUnit.month => 'ヶ月ごと',
      };

  static IntervalUnit fromName(String? name) =>
      IntervalUnit.values.firstWhere((u) => u.name == name,
          orElse: () => IntervalUnit.month);
}

/// A normalized recurrence: "every [count] [unit]s". Every subscription maps to
/// one of these regardless of which preset/custom cycle was chosen.
class Recurrence {
  const Recurrence(this.count, this.unit);
  final int count;
  final IntervalUnit unit;

  /// Average occurrences per month → drives monthly-equivalent spend.
  double get monthlyFactor {
    final c = count <= 0 ? 1 : count;
    return switch (unit) {
      IntervalUnit.day => (365.25 / 12) / c,
      IntervalUnit.week => (52 / 12) / c,
      IntervalUnit.month => 1 / c,
    };
  }

  double get yearlyFactor => monthlyFactor * 12;
}

class Billing {
  Billing._();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _advance(DateTime d, Recurrence r, int anchorDay) {
    final c = r.count <= 0 ? 1 : r.count;
    return switch (r.unit) {
      IntervalUnit.day => d.add(Duration(days: c)),
      IntervalUnit.week => d.add(Duration(days: c * 7)),
      IntervalUnit.month => _addMonths(d, c, anchorDay),
    };
  }

  static DateTime _retreat(DateTime d, Recurrence r, int anchorDay) {
    final c = r.count <= 0 ? 1 : r.count;
    return switch (r.unit) {
      IntervalUnit.day => d.subtract(Duration(days: c)),
      IntervalUnit.week => d.subtract(Duration(days: c * 7)),
      IntervalUnit.month => _addMonths(d, -c, anchorDay),
    };
  }

  /// Fast-forwards [from] toward [target] by whole day/week periods so callers
  /// don't loop over huge spans (e.g. a daily cycle anchored years ago). No-op
  /// for month recurrences (calendar-month counts are always small). Returns a
  /// date at or before [target], at most one period earlier.
  static DateTime _skipTo(DateTime from, DateTime target, Recurrence r) {
    if (!from.isBefore(target) || r.unit == IntervalUnit.month) return from;
    final c = r.count <= 0 ? 1 : r.count;
    final periodDays = r.unit == IntervalUnit.week ? c * 7 : c;
    if (periodDays <= 0) return from;
    final diff = target.difference(from).inDays;
    if (diff <= 0) return from;
    return from.add(Duration(days: (diff ~/ periodDays) * periodDays));
  }

  /// Next occurrence of the billing date on or after [from], starting from the
  /// [anchor] (first payment date) and advancing by the recurrence.
  static DateTime nextPaymentDate(
    DateTime anchor,
    Recurrence recurrence, {
    DateTime? from,
  }) {
    final today = _dateOnly(from ?? DateTime.now());
    var next = _skipTo(_dateOnly(anchor), today, recurrence);
    var guard = 0;
    while (next.isBefore(today) && ++guard < 5000) {
      next = _advance(next, recurrence, anchor.day);
    }
    return next;
  }

  /// The payment date of the *current* period (the most recent one on or
  /// before today) — the start of the running progress bar.
  static DateTime currentPeriodStart(
    DateTime anchor,
    Recurrence recurrence, {
    DateTime? from,
  }) {
    final next = nextPaymentDate(anchor, recurrence, from: from);
    return _retreat(next, recurrence, anchor.day);
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
  static double periodProgress(DateTime anchor, Recurrence recurrence,
      {DateTime? from}) {
    final today = _dateOnly(from ?? DateTime.now());
    final start = currentPeriodStart(anchor, recurrence, from: from);
    final next = nextPaymentDate(anchor, recurrence, from: from);
    final total = next.difference(start).inDays;
    if (total <= 0) return 1;
    final elapsed = today.difference(start).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// All payment dates for a subscription that fall within [start]..[end].
  static List<DateTime> paymentsInRange(
    DateTime anchor,
    Recurrence recurrence,
    DateTime start,
    DateTime end,
  ) {
    final result = <DateTime>[];
    final anchorDate = _dateOnly(anchor);
    // Fast-forward toward the range start (day/week) to avoid long loops when
    // the anchor is far in the past.
    var d = _skipTo(anchorDate, _dateOnly(start), recurrence);
    // Rewind to at or before the range start (but never past the anchor: a
    // subscription has no payments before its first payment date).
    var guard = 0;
    while (d.isAfter(start) && d.isAfter(anchorDate) && ++guard < 5000) {
      d = _retreat(d, recurrence, anchor.day);
    }
    // Advance and collect. Skip anything before the range start or the anchor.
    guard = 0;
    while ((d.isBefore(end) || d.isAtSameMomentAs(end)) && ++guard < 5000) {
      if (!d.isBefore(start) && !d.isBefore(anchorDate)) result.add(d);
      d = _advance(d, recurrence, anchor.day);
    }
    return result;
  }
}
