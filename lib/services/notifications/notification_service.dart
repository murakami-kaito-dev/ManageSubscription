import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

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

  /// Whether the OS currently allows this app to show notifications. Used to
  /// surface the "iOSの設定で通知がオフです" banner so a set reminder never
  /// fails silently.
  Future<bool> hasPermission() async {
    if (!_ready) return false;
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final s = await ios.checkPermissions();
        return s?.isEnabled ?? false;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return (await android?.areNotificationsEnabled()) ?? true;
    } catch (e) {
      debugPrint('permission check skipped: $e');
      return false;
    }
  }

  /// Opens this app's page in the system Settings (iOS: includes 通知), so the
  /// user can re-enable notifications when they've been turned off at the OS
  /// level.
  Future<void> openSystemSettings() async {
    try {
      // iOS: "app-settings:" == UIApplication.openSettingsURLString (App
      // Store-safe); opens this app's Settings page, which includes 通知.
      // (iOS-only distribution; on Android this simply no-ops.)
      await launchUrl(Uri.parse('app-settings:'));
    } catch (e) {
      debugPrint('open settings skipped: $e');
    }
  }

  /// Builds the platform details for one reminder. When the subscription has a
  /// custom **image** (not an emoji/letter), it's used as the notification's
  /// icon: an Android large icon and an iOS attachment thumbnail.
  Future<NotificationDetails> _detailsFor(Subscription s) async {
    final file = ImagePaths.resolve(s.imagePath);
    final stablePath = (file != null && file.existsSync()) ? file.path : null;

    // iOS UNNotificationAttachment TAKES OWNERSHIP of the file it's given and
    // MOVES it out of our documents directory — which would delete the icon the
    // app itself displays. So hand iOS a disposable *copy* in the temp dir and
    // keep the original for the Android icon and the in-app avatar.
    String? iosAttachmentPath;
    if (stablePath != null) {
      try {
        final tmp = await getTemporaryDirectory();
        final dest = p.join(tmp.path,
            'notif_${s.id}_${DateTime.now().millisecondsSinceEpoch}.png');
        await File(stablePath).copy(dest);
        iosAttachmentPath = dest;
      } catch (e) {
        debugPrint('notif attachment copy failed: $e');
      }
    }

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
        // Android only READS the file (doesn't move it) so the stable path is
        // fine and survives until the alarm fires.
        largeIcon:
            stablePath != null ? FilePathAndroidBitmap(stablePath) : null,
      ),
      // Foreground: play the SOUND (presentSound) but suppress the OS banner
      // (presentAlert/Banner = false) — the guaranteed in-app banner
      // (ForegroundReminderHost) provides the foreground visual, avoiding a
      // double notification. Background presentation is unaffected by these.
      iOS: DarwinNotificationDetails(
        presentAlert: false,
        presentBanner: false,
        presentSound: true,
        presentBadge: true,
        attachments: iosAttachmentPath != null
            ? [DarwinNotificationAttachment(iosAttachmentPath)]
            : null,
      ),
    );
  }

  /// Reschedules reminders for the whole list, driven purely by each
  /// subscription's per-item notify rules (the single source of truth) — there
  /// is no separate app-wide on/off gate. Whether the OS actually shows them is
  /// governed only by the system notification permission. Free tier is already
  /// capped to a single reminder rule per subscription by the caller.
  Future<void> rescheduleAll(List<Subscription> subs) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      var id = 0;
      final now = tz.TZDateTime.now(tz.local);
      for (final s in subs) {
        if (s.isPaused) continue;
        if (s.notifyRules.isEmpty) continue;
        final due = s.nextPaymentDate;
        final amount = CurrencyFormatter(s.currency).format(s.amount);
        // Build details (incl. the disposable iOS attachment copy) once per sub.
        final details = await _detailsFor(s);
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
            details,
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
