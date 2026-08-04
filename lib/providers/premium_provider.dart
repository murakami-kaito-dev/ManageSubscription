import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dev_config.dart';
import '../core/monetization/iap.dart';
import 'core_providers.dart';

/// Snapshot of the user's entitlement for the paywall / settings UI.
class Entitlement {
  const Entitlement({
    required this.isPremium,
    required this.kind,
    required this.trialDaysLeft,
    required this.devUnlocked,
  });

  /// True when every premium feature is unlocked (paid OR in trial OR dev).
  final bool isPremium;
  final PlanKind kind;

  /// Days remaining in the free trial (0 when not trialing).
  final int trialDaysLeft;
  final bool devUnlocked;

  bool get isTrialing => kind == PlanKind.trial;
}

/// Exposes premium access as a reactive bool used by every feature gate.
/// Full access = a paid entitlement OR the 2-week free trial is still running.
/// Developer builds ([kDevUnlockAll]) always report premium.
class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    if (kDevUnlockAll) return true;
    final service = ref.watch(purchaseServiceProvider);
    void listener() => state = service.hasFullAccess;
    service.isPremium.addListener(listener);
    ref.onDispose(() => service.isPremium.removeListener(listener));
    return service.hasFullAccess;
  }

  Future<bool> purchase(PlanKind kind) =>
      ref.read(purchaseServiceProvider).purchase(kind);
  Future<bool> restore() => ref.read(purchaseServiceProvider).restore();

  /// Debug-only toggle used from the settings screen (long-press the version).
  Future<void> debugToggle() async {
    final service = ref.read(purchaseServiceProvider);
    await service.debugSetPremium(!service.hasPaid);
  }
}

final premiumProvider = NotifierProvider<PremiumNotifier, bool>(
  PremiumNotifier.new,
);

/// Richer entitlement snapshot (plan + trial days) for the paywall & settings.
final entitlementProvider = Provider<Entitlement>((ref) {
  ref.watch(premiumProvider); // rebuild when the paid flag changes
  final s = ref.watch(purchaseServiceProvider);
  if (kDevUnlockAll) {
    return const Entitlement(
      isPremium: true,
      kind: PlanKind.lifetime,
      trialDaysLeft: 0,
      devUnlocked: true,
    );
  }
  return Entitlement(
    isPremium: s.hasFullAccess,
    kind: s.currentPlan,
    trialDaysLeft: s.isTrialActive ? s.trialDaysLeft : 0,
    devUnlocked: false,
  );
});
