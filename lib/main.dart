import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/utils/image_paths.dart';
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

  // Cache the images directory so avatars can resolve icon files synchronously.
  await ImagePaths.init();

  // Load the day's FX rates (cached; refreshes once per day). Best-effort.
  await RatesService(prefs).load();

  final purchases = PurchaseService(prefs);
  await purchases.init();

  // Notifications init is best-effort and must never block startup.
  // Ads are disabled in v1 (kAdsEnabled = false) so AdService.init() is not
  // called and the AdMob SDK never starts.
  if (kAdsEnabled) await AdService.instance.init();
  await NotificationService.instance.init();

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

  // Reschedule reminders OFF the launch critical path: requesting permission,
  // loading all rows and scheduling one OS notification per subscription are
  // O(item count) platform round-trips (plus a temp-image copy each). Doing
  // this after runApp keeps startup fast even with a large library.
  // Reschedule from each subscription's own notify rules (the single source of
  // truth). We do NOT prompt for OS permission at cold start — that's asked
  // contextually when the user adds a reminder, and the home banner nudges them
  // to Settings if notifications are off at the OS level.
  Future(() async {
    try {
      final subs = await SubscriptionRepository(db).getAll();
      await NotificationService.instance.rescheduleAll(subs);
    } catch (_) {/* best-effort */}
  });
}
