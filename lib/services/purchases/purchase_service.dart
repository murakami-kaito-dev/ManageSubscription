import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/monetization/iap.dart';

/// Entitlement + trial service.
///
/// RevenueCat (`purchases_flutter`) is wired in, but guarded so the app runs
/// end-to-end **without** live API keys: when [useRevenueCat] is false (or a
/// RevenueCat call throws), it falls back to locally-persisted flags. Flip
/// [useRevenueCat] and drop in the API keys to go fully live.
///
/// Access model: full access = an active paid entitlement (subscription OR the
/// one-time purchase) **or** the 2-week free trial is still running.
class PurchaseService {
  PurchaseService(this._prefs, {this.useRevenueCat = true});
  final SharedPreferences _prefs;

  /// Live billing via RevenueCat. Defaults on (iOS is live). Tests pass false to
  /// force the offline mock path. iOS uses the public SDK key below; Android
  /// isn't distributed yet (see StoreLinks.androidDistribution) so its key stays
  /// a placeholder.
  final bool useRevenueCat;
  static const String _apiKeyAndroid = 'goog_YOUR_KEY';
  static const String _apiKeyIos = 'appl_kEznevQmXbYglmMxSOHrKEPtfcr';

  static const String _paidKey = 'is_premium'; // paid entitlement flag
  static const String _planKey = 'plan_kind';

  /// Fires whenever the *paid* entitlement changes. Trial changes are
  /// time-based and read on demand.
  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  Future<void> init() async {
    isPremium.value = _prefs.getBool(_paidKey) ?? false;

    if (!useRevenueCat) return;
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final key = defaultTargetPlatform == TargetPlatform.iOS
          ? _apiKeyIos
          : _apiKeyAndroid;
      await Purchases.configure(PurchasesConfiguration(key));
      final info = await Purchases.getCustomerInfo();
      await _applyCustomerInfo(info);
    } catch (e) {
      debugPrint('RevenueCat init skipped: $e');
    }
  }

  // ── Entitlement ────────────────────────────────────────────────────────
  bool get hasPaid => isPremium.value;

  /// Full access = an active paid entitlement. For subscriptions this includes
  /// the App Store free-trial (intro offer) period, which RevenueCat reports as
  /// active. Fresh installs are the free plan — there is no app-side trial.
  bool get hasFullAccess => hasPaid;

  /// The current plan for display. Paid plan wins; otherwise free.
  PlanKind get currentPlan {
    if (hasPaid) {
      final name = _prefs.getString(_planKey);
      return PlanKind.values.firstWhere(
        (p) => p.name == name && p.isPaid,
        orElse: () => PlanKind.lifetime,
      );
    }
    return PlanKind.free;
  }

  Future<void> _applyPaid(bool value, {PlanKind? plan}) async {
    isPremium.value = value;
    await _prefs.setBool(_paidKey, value);
    if (value && plan != null) {
      await _prefs.setString(_planKey, plan.name);
    } else if (!value) {
      await _prefs.remove(_planKey);
    }
  }

  Future<void> _applyCustomerInfo(CustomerInfo info) async {
    final ent = info.entitlements.all[Iap.entitlement];
    final active = ent?.isActive ?? false;
    final plan =
        ent != null ? Iap.planForProduct(ent.productIdentifier) : null;
    await _applyPaid(active, plan: plan);
  }

  // ── Purchase / restore ───────────────────────────────────────────────────
  /// Purchases the product for [kind]. Returns true when access was granted.
  Future<bool> purchase(PlanKind kind) async {
    if (!kind.isPaid) return false;
    if (!useRevenueCat) {
      // Mock: grant immediately so the flow is testable without the stores.
      await _applyPaid(true, plan: kind);
      return true;
    }
    final wanted = Iap.productId(kind);
    try {
      // 1) Prefer a package from the configured offerings. Search ALL offerings
      //    (not only `current`): a mis-set "current" flag on the RevenueCat
      //    dashboard would otherwise leave `availablePackages` empty and make
      //    the purchase silently fail *before* the StoreKit sheet appears —
      //    which is exactly the "決済シートが出ない" symptom.
      final offerings = await Purchases.getOfferings();
      Package? pkg;
      for (final offering in offerings.all.values) {
        for (final p in offering.availablePackages) {
          if (p.storeProduct.identifier == wanted) {
            pkg = p;
            break;
          }
        }
        if (pkg != null) break;
      }
      if (pkg != null) {
        // ignore: deprecated_member_use
        final result = await Purchases.purchasePackage(pkg);
        await _applyCustomerInfo(result.customerInfo);
        return hasPaid;
      }

      // 2) Fallback: fetch the product straight from the store and buy it. This
      //    still opens the StoreKit sheet when the RevenueCat offering isn't
      //    configured/current, as long as the product exists in App Store
      //    Connect. Lifetime is a non-subscription product, so pick the right
      //    category (matters on Android; ignored on iOS).
      final category = kind == PlanKind.lifetime
          ? ProductCategory.nonSubscription
          : ProductCategory.subscription;
      final products =
          await Purchases.getProducts([wanted], productCategory: category);
      if (products.isNotEmpty) {
        // ignore: deprecated_member_use
        final result = await Purchases.purchaseStoreProduct(products.first);
        await _applyCustomerInfo(result.customerInfo);
        return hasPaid;
      }

      debugPrint('No package/product found for $wanted');
      return false;
    } on PlatformException catch (e) {
      // A user-initiated cancel is not a failure worth alarming about; keep the
      // current entitlement and let the paywall stay open silently.
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return hasPaid;
      }
      debugPrint('purchase failed: $e');
      return false;
    } catch (e) {
      debugPrint('purchase failed: $e');
      return false;
    }
  }

  Future<bool> restore() async {
    if (!useRevenueCat) return hasPaid;
    try {
      final info = await Purchases.restorePurchases();
      await _applyCustomerInfo(info);
      return hasPaid;
    } catch (e) {
      debugPrint('restore failed: $e');
      return false;
    }
  }

  /// Live localized prices from the store, falling back to the constants.
  Future<Map<PlanKind, String>> loadPrices() async {
    final fallback = {
      PlanKind.lifetime: Iap.priceLifetime,
      PlanKind.monthly: Iap.priceMonthly,
      PlanKind.yearly: Iap.priceYearly,
    };
    if (!useRevenueCat) return fallback;
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const [];
      final out = Map<PlanKind, String>.from(fallback);
      for (final p in packages) {
        final kind = Iap.planForProduct(p.storeProduct.identifier);
        if (kind != null) out[kind] = p.storeProduct.priceString;
      }
      return out;
    } catch (_) {
      return fallback;
    }
  }

  /// Debug helper to toggle the paid entitlement (settings long-press).
  Future<void> debugSetPremium(bool value) =>
      _applyPaid(value, plan: value ? PlanKind.lifetime : null);
}
