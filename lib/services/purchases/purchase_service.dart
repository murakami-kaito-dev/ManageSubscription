import 'package:flutter/foundation.dart';
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
  PurchaseService(this._prefs);
  final SharedPreferences _prefs;

  /// Set true and provide real keys to enable live billing.
  static const bool useRevenueCat = false;
  static const String _apiKeyAndroid = 'goog_YOUR_KEY';
  static const String _apiKeyIos = 'appl_YOUR_KEY';

  static const String _paidKey = 'is_premium'; // paid entitlement flag
  static const String _firstLaunchKey = 'first_launch_ms';
  static const String _planKey = 'plan_kind';

  /// Fires whenever the *paid* entitlement changes. Trial changes are
  /// time-based and read on demand.
  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  Future<void> init() async {
    // Record the first-launch timestamp once; it anchors the free trial.
    if (!_prefs.containsKey(_firstLaunchKey)) {
      await _prefs.setInt(
          _firstLaunchKey, DateTime.now().millisecondsSinceEpoch);
    }
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

  // ── Trial ──────────────────────────────────────────────────────────────
  DateTime get trialStart => DateTime.fromMillisecondsSinceEpoch(
      _prefs.getInt(_firstLaunchKey) ?? DateTime.now().millisecondsSinceEpoch);

  DateTime get trialEnd => trialStart.add(Iap.trialDuration);

  bool get isTrialActive => DateTime.now().isBefore(trialEnd) && !hasPaid;

  int get trialDaysLeft {
    final ms = trialEnd.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / Duration.millisecondsPerDay).ceil();
  }

  // ── Entitlement ────────────────────────────────────────────────────────
  bool get hasPaid => isPremium.value;

  /// Full access = paid OR still in the free trial.
  bool get hasFullAccess => hasPaid || isTrialActive;

  /// The current plan for display. Paid plan wins; then trial; then free.
  PlanKind get currentPlan {
    if (hasPaid) {
      final name = _prefs.getString(_planKey);
      return PlanKind.values.firstWhere(
        (p) => p.name == name && p.isPaid,
        orElse: () => PlanKind.lifetime,
      );
    }
    if (isTrialActive) return PlanKind.trial;
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
    try {
      final wanted = Iap.productId(kind);
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const [];
      Package? pkg;
      for (final p in packages) {
        if (p.storeProduct.identifier == wanted) {
          pkg = p;
          break;
        }
      }
      if (pkg == null) {
        debugPrint('No package found for $wanted');
        return false;
      }
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(pkg);
      await _applyCustomerInfo(result.customerInfo);
      return hasPaid;
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
