import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/repositories/category_repository.dart';
import '../data/repositories/payment_method_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../services/ads/ad_service.dart';
import '../services/csv/csv_export_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/purchases/purchase_service.dart';

/// Overridden in main() with the opened database.
final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// Overridden in main() with the loaded SharedPreferences.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden'),
);

/// Overridden in main() with the initialized PurchaseService.
final purchaseServiceProvider = Provider<PurchaseService>(
  (ref) => throw UnimplementedError('purchaseServiceProvider must be overridden'),
);

final adServiceProvider = Provider<AdService>((ref) => AdService.instance);
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);
final csvExportServiceProvider =
    Provider<CsvExportService>((ref) => const CsvExportService());

// ── Repositories ────────────────────────────────────────────────────────
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.watch(databaseProvider)),
);
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);
final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>(
  (ref) => PaymentMethodRepository(ref.watch(databaseProvider)),
);
