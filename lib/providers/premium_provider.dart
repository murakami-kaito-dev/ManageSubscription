import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dev_config.dart';
import '../core/monetization/iap.dart';
import 'core_providers.dart';

/// Snapshot of the user's entitlement for the paywall / settings UI.
class Entitlement {
  const Entitlement({
    required this.isPremium,
    required this.kind,
    required this.devUnlocked,
  });

  /// True when every premium feature is unlocked (paid entitlement OR dev).
  final bool isPremium;
  final PlanKind kind;
  final bool devUnlocked;
}

/// Exposes premium access as a reactive bool used by every feature gate.
/// Full access = an active paid entitlement (subscription incl. its App Store
/// free-trial period, or the one-time purchase). Fresh installs are free.
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
      devUnlocked: true,
    );
  }
  return Entitlement(
    isPremium: s.hasFullAccess,
    kind: s.currentPlan,
    devUnlocked: false,
  );
});
