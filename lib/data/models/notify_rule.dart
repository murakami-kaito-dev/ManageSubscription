import 'package:flutter/material.dart';

/// A single "remind me N days before, at HH:MM" rule (Google-Calendar style).
@immutable
class NotifyRule {
  const NotifyRule({required this.daysBefore, this.hour = 9, this.minute = 0});

  final int daysBefore;
  final int hour;
  final int minute;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get dayLabel => daysBefore == 0 ? '当日' : '$daysBefore日前';

  String get label => '$dayLabel $timeLabel';

  NotifyRule copyWith({int? daysBefore, int? hour, int? minute}) => NotifyRule(
        daysBefore: daysBefore ?? this.daysBefore,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  /// Serialized token: "1@0900" (days@HHMM).
  String toToken() =>
      '$daysBefore@${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}';

  static NotifyRule? fromToken(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    // Backward compatibility: a bare "1" means "1 day before at 09:00".
    if (!t.contains('@')) {
      final d = int.tryParse(t);
      return d == null ? null : NotifyRule(daysBefore: d);
    }
    final parts = t.split('@');
    final d = int.tryParse(parts[0]);
    if (d == null) return null;
    final hhmm = parts.length > 1 ? parts[1] : '0900';
    final hh = int.tryParse(hhmm.padRight(4, '0').substring(0, 2)) ?? 9;
    final mm = int.tryParse(hhmm.padRight(4, '0').substring(2, 4)) ?? 0;
    return NotifyRule(daysBefore: d, hour: hh, minute: mm);
  }

  static String encode(List<NotifyRule> rules) =>
      rules.map((r) => r.toToken()).join(',');

  static List<NotifyRule> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map(NotifyRule.fromToken)
        .whereType<NotifyRule>()
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      other is NotifyRule &&
      other.daysBefore == daysBefore &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(daysBefore, hour, minute);
}
