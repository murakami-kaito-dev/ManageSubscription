import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dev_config.dart';
import 'core_providers.dart';

/// Exposes the current premium entitlement as a reactive bool, mirroring the
/// PurchaseService's ValueNotifier. Developer builds ([kDevUnlockAll]) always
/// report premium.
class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    if (kDevUnlockAll) return true;
    final service = ref.watch(purchaseServiceProvider);
    void listener() => state = service.isPremium.value;
    service.isPremium.addListener(listener);
    ref.onDispose(() => service.isPremium.removeListener(listener));
    return service.isPremium.value;
  }

  Future<bool> purchase() => ref.read(purchaseServiceProvider).purchase();
  Future<bool> restore() => ref.read(purchaseServiceProvider).restore();

  /// Debug-only toggle used from the settings screen (long-press the crown).
  Future<void> debugToggle() async {
    final service = ref.read(purchaseServiceProvider);
    await service.debugSetPremium(!service.isPremium.value);
  }
}

final premiumProvider = NotifierProvider<PremiumNotifier, bool>(
  PremiumNotifier.new,
);
