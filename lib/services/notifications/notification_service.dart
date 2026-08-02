import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/subscription.dart';

/// Local reminders before a payment date. Fully on-device; no server.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications init skipped: $e');
    }
  }

  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission skipped: $e');
    }
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'payment_reminders',
      '支払いリマインダー',
      channelDescription: '支払い日が近づいたらお知らせします',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Reschedules reminders for the whole list. Free tier is already capped to a
  /// single reminder rule per subscription by the caller.
  Future<void> rescheduleAll(List<Subscription> subs, {required bool enabled}) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (!enabled) return;
      var id = 0;
      final now = tz.TZDateTime.now(tz.local);
      for (final s in subs) {
        if (s.isPaused) continue;
        for (final rule in s.notifyRules) {
          final fireDate =
              s.nextPaymentDate.subtract(Duration(days: rule.daysBefore));
          final scheduled = tz.TZDateTime(tz.local, fireDate.year,
              fireDate.month, fireDate.day, rule.hour, rule.minute);
          if (scheduled.isBefore(now)) continue;
          await _plugin.zonedSchedule(
            id++,
            '${s.name} の支払いが近づいています',
            rule.daysBefore == 0
                ? '本日が支払い日です'
                : '${rule.daysBefore}日後（${s.nextPaymentDate.month}/${s.nextPaymentDate.day}）に支払いがあります',
            scheduled,
            _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    } catch (e) {
      debugPrint('reschedule skipped: $e');
    }
  }
}
