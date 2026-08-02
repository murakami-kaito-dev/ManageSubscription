import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium entitlement service.
///
/// RevenueCat (`purchases_flutter`) is wired in, but guarded so the app runs
/// end-to-end **without** live API keys: when [useRevenueCat] is false (or a
/// RevenueCat call throws), it falls back to a locally-persisted flag. Flip the
/// flag and drop in the API key + entitlement id to go fully live.
class PurchaseService {
  PurchaseService(this._prefs);
  final SharedPreferences _prefs;

  /// Set true and provide real keys to enable live billing.
  static const bool useRevenueCat = false;
  static const String _apiKeyAndroid = 'goog_YOUR_KEY';
  static const String _apiKeyIos = 'appl_YOUR_KEY';
  static const String entitlementId = 'premium';
  static const String _prefsKey = 'is_premium';

  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  Future<void> init() async {
    isPremium.value = _prefs.getBool(_prefsKey) ?? false;
    if (!useRevenueCat) return;
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final key = defaultTargetPlatform == TargetPlatform.iOS
          ? _apiKeyIos
          : _apiKeyAndroid;
      await Purchases.configure(PurchasesConfiguration(key));
      final info = await Purchases.getCustomerInfo();
      _apply(info.entitlements.all[entitlementId]?.isActive ?? false);
    } catch (e) {
      debugPrint('RevenueCat init skipped: $e');
    }
  }

  Future<void> _apply(bool value) async {
    isPremium.value = value;
    await _prefs.setBool(_prefsKey, value);
  }

  /// Returns true when premium was granted.
  Future<bool> purchase() async {
    if (!useRevenueCat) {
      // Mock: grant immediately (simulates a successful trial start).
      await _apply(true);
      return true;
    }
    try {
      final offerings = await Purchases.getOfferings();
      final pkg = offerings.current?.availablePackages.first;
      if (pkg == null) return false;
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(pkg);
      final active =
          result.customerInfo.entitlements.all[entitlementId]?.isActive ??
              false;
      await _apply(active);
      return active;
    } catch (e) {
      debugPrint('purchase failed: $e');
      return false;
    }
  }

  Future<bool> restore() async {
    if (!useRevenueCat) return isPremium.value;
    try {
      final info = await Purchases.restorePurchases();
      final active =
          info.entitlements.all[entitlementId]?.isActive ?? false;
      await _apply(active);
      return active;
    } catch (e) {
      debugPrint('restore failed: $e');
      return false;
    }
  }

  /// Debug helper to toggle premium off (used by the settings long-press).
  Future<void> debugSetPremium(bool value) => _apply(value);
}
