import 'notify_rule.dart';
import 'subscription.dart';

/// One reminder occurrence: subscription [sub] fires at [fireAt] for the payment
/// due on [due], per [rule].
class ReminderFire {
  ReminderFire(this.sub, this.rule, this.fireAt, this.due);
  final Subscription sub;
  final NotifyRule rule;
  final DateTime fireAt;
  final DateTime due;
  String get key => '${sub.id}|${fireAt.toIso8601String()}';
}

/// Pure computation of the reminder occurrences still in the future (relative to
/// [now]), soonest first. Paused subscriptions are excluded. Extracted so the
/// fire-time math is unit-testable.
///
/// Shared by the in-app foreground banner (ForegroundReminderHost) and the OS
/// notification scheduler (NotificationService), so both always agree on what
/// fires when — and the chronological order doubles as the iOS badge numbering
/// (1st delivery → badge 1, 2nd → 2, …).
List<ReminderFire> computeUpcomingReminders(
    List<Subscription> subs, DateTime now) {
  final out = <ReminderFire>[];
  for (final s in subs) {
    if (s.isPaused) continue;
    final due = s.nextPaymentDate;
    for (final r in s.notifyRules) {
      final fireAt = DateTime(due.year, due.month, due.day, r.hour, r.minute)
          .subtract(Duration(days: r.daysBefore));
      if (fireAt.isAfter(now)) out.add(ReminderFire(s, r, fireAt, due));
    }
  }
  out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return out;
}
