/// Single source of truth for every free-tier restriction. Keeping the numbers
/// and the boolean gates here means screens never hard-code a limit.
class PremiumLimits {
  PremiumLimits._();

  static const int maxSubscriptions = 8;
  static const int maxCategories = 3;
  static const int maxPaymentMethods = 3;
  static const int maxNotifyRules = 1;

  // Feature gates (true = allowed only for premium).
  static bool canAddSubscription(bool isPremium, int current) =>
      isPremium || current < maxSubscriptions;
  static bool canAddCategory(bool isPremium, int current) =>
      isPremium || current < maxCategories;
  static bool canAddPaymentMethod(bool isPremium, int current) =>
      isPremium || current < maxPaymentMethods;
  static int notifyRuleLimit(bool isPremium) =>
      isPremium ? 99 : maxNotifyRules;

  // Pure premium-only capabilities.
  static bool canAttachImage(bool isPremium) => isPremium;
  static bool canExportCsv(bool isPremium) => isPremium;
  static bool canBreakdownByCategoryOrMethod(bool isPremium) => isPremium;

  // Now free for everyone (per product decision): sorting & theme color.
  static bool canAutoSort(bool isPremium) => true;
  static bool canChangeTheme(bool isPremium) => true;

  /// Free users may only view the current month/year in calendar & history.
  static bool canViewAllPeriods(bool isPremium) => isPremium;
}
