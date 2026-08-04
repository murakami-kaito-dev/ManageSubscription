/// Monetization model: ① Free, ② Subscription (monthly / yearly), ③ one-time
/// (lifetime), preceded by a 2-week free trial that unlocks everything.
///
/// All three paid products map to a single RevenueCat entitlement ([entitlement])
/// so "buy any one → full access" is a dashboard setting, not app logic.
enum PlanKind { free, trial, lifetime, monthly, yearly }

extension PlanKindX on PlanKind {
  bool get isPaid =>
      this == PlanKind.lifetime ||
      this == PlanKind.monthly ||
      this == PlanKind.yearly;

  String get label => switch (this) {
        PlanKind.free => '無料プラン',
        PlanKind.trial => '無料体験中',
        PlanKind.lifetime => '買い切り（永久）',
        PlanKind.monthly => '月額プラン',
        PlanKind.yearly => '年額プラン',
      };
}

class Iap {
  Iap._();

  /// RevenueCat entitlement identifier that all paid products grant.
  static const String entitlement = 'premium';

  /// App Store Connect / Play product identifiers.
  static const String lifetimeId = 'subsc_pro_lifetime';
  static const String monthlyId = 'subsc_pro_monthly';
  static const String yearlyId = 'subsc_pro_yearly';

  /// Free trial length before any plan choice is required.
  static const Duration trialDuration = Duration(days: 14);

  /// Fallback display prices shown in mock builds or before RevenueCat's live
  /// localized prices load. The real charge always comes from the store.
  static const String priceLifetime = '¥980';
  static const String priceMonthly = '¥300';
  static const String priceYearly = '¥1,800';

  static String productId(PlanKind kind) => switch (kind) {
        PlanKind.lifetime => lifetimeId,
        PlanKind.monthly => monthlyId,
        PlanKind.yearly => yearlyId,
        _ => '',
      };

  static PlanKind? planForProduct(String productId) {
    if (productId == lifetimeId) return PlanKind.lifetime;
    if (productId == monthlyId) return PlanKind.monthly;
    if (productId == yearlyId) return PlanKind.yearly;
    return null;
  }
}
