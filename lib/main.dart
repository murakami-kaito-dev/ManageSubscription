import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/repositories/subscription_repository.dart';
import 'providers/core_providers.dart';
import 'services/ads/ad_service.dart';
import 'services/currency/rates_service.dart';
import 'services/notifications/notification_service.dart';
import 'services/purchases/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');

  // Open the local DB and load persisted settings before the first frame so
  // repositories can be provided synchronously.
  final db = await AppDatabase.instance.database;
  final prefs = await SharedPreferences.getInstance();

  // Load the day's FX rates (cached; refreshes once per day). Best-effort.
  await RatesService(prefs).load();

  final purchases = PurchaseService(prefs);
  await purchases.init();

  // Ads & notifications init are best-effort and must never block startup.
  await AdService.instance.init();
  await NotificationService.instance.init();

  // Ensure reminders are (re)scheduled on every launch — otherwise seeded or
  // previously-added subscriptions would never schedule until the user edits
  // one. Request permission first when notifications are enabled.
  final notifyEnabled = prefs.getBool('settings_notify') ?? true;
  if (notifyEnabled) {
    await NotificationService.instance.requestPermission();
  }
  try {
    final subs = await SubscriptionRepository(db).getAll();
    await NotificationService.instance
        .rescheduleAll(subs, enabled: notifyEnabled);
  } catch (_) {/* best-effort */}

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        prefsProvider.overrideWithValue(prefs),
        purchaseServiceProvider.overrideWithValue(purchases),
      ],
      child: const ManageSubscriptionApp(),
    ),
  );
}
