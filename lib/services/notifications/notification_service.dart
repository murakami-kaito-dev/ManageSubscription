import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/currency.dart';
import '../../core/utils/image_paths.dart';
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
      // CRITICAL: without setting the device's local zone, tz.local is UTC and
      // every reminder fires at the wrong wall-clock time (e.g. 9:00 JST would
      // be scheduled as 9:00 UTC = 18:00 JST, or skipped as "in the past").
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (e) {
        debugPrint('Local timezone lookup failed, using UTC: $e');
      }

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
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      // Needed to fire at an exact wall-clock time on Android 12+.
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Notification permission skipped: $e');
    }
  }

  /// Builds the platform details for one reminder. When the subscription has a
  /// custom **image** (not an emoji/letter), it's used as the notification's
  /// icon: an Android large icon and an iOS attachment thumbnail.
  NotificationDetails _detailsFor(Subscription s) {
    final file = ImagePaths.resolve(s.imagePath);
    final imagePath = (file != null && file.existsSync()) ? file.path : null;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        'payment_reminders',
        '支払いリマインダー',
        channelDescription: '支払い日が近づいたらお知らせします',
        importance: Importance.high,
        priority: Priority.high,
        // Explicitly ask for sound + vibration on the channel.
        playSound: true,
        enableVibration: true,
        largeIcon:
            imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
      ),
      // presentAlert/Banner/Sound = show even while the app is in the
      // foreground (iOS otherwise silently swallows foreground notifications).
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        attachments: imagePath != null
            ? [DarwinNotificationAttachment(imagePath)]
            : null,
      ),
    );
  }

  /// Reschedules reminders for the whole list. Free tier is already capped to a
  /// single reminder rule per subscription by the caller.
  Future<void> rescheduleAll(List<Subscription> subs,
      {required bool enabled}) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (!enabled) return;
      var id = 0;
      final now = tz.TZDateTime.now(tz.local);
      for (final s in subs) {
        if (s.isPaused) continue;
        final due = s.nextPaymentDate;
        final amount = CurrencyFormatter(s.currency).format(s.amount);
        for (final rule in s.notifyRules) {
          final fireDate = due.subtract(Duration(days: rule.daysBefore));
          final scheduled = tz.TZDateTime(tz.local, fireDate.year,
              fireDate.month, fireDate.day, rule.hour, rule.minute);
          if (!scheduled.isAfter(now)) continue;
          await _schedule(
            id++,
            '${s.name} の支払い',
            rule.daysBefore == 0
                ? '本日 ${due.month}月${due.day}日に $amount の支払いがあります'
                : '${due.month}月${due.day}日（${rule.daysBefore}日後）に $amount の支払いがあります',
            scheduled,
            _detailsFor(s),
          );
        }
      }
    } catch (e) {
      debugPrint('reschedule skipped: $e');
    }
  }

  /// Schedules one reminder, preferring an exact alarm and gracefully falling
  /// back to an inexact one if exact alarms aren't permitted.
  Future<void> _schedule(int id, String title, String body,
      tz.TZDateTime when, NotificationDetails details) async {
    try {
      await _plugin.zonedSchedule(
        id, title, body, when, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id, title, body, when, details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('schedule failed for $id: $e');
      }
    }
  }
}
