import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../data/models/category.dart';
import '../data/models/payment_method.dart';
import '../data/models/subscription.dart';
import 'core_providers.dart';
import 'settings_provider.dart';

// ── Subscriptions ─────────────────────────────────────────────────────────
class SubscriptionsNotifier extends AsyncNotifier<List<Subscription>> {
  @override
  Future<List<Subscription>> build() =>
      ref.watch(subscriptionRepositoryProvider).getAll();

  Future<void> save(Subscription s) async {
    await ref.read(subscriptionRepositoryProvider).upsert(s);
    ref.invalidateSelf();
    await future;
    _reschedule();
  }

  Future<void> delete(String id) async {
    await ref.read(subscriptionRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
    _reschedule();
  }

  Future<void> setPaused(String id, bool paused) async {
    await ref.read(subscriptionRepositoryProvider).setPaused(id, paused);
    ref.invalidateSelf();
    await future;
    _reschedule();
  }

  Future<void> reorder(List<Subscription> ordered) async {
    // Optimistic: reflect new order immediately.
    state = AsyncData(ordered);
    await ref.read(subscriptionRepositoryProvider).saveOrder(ordered);
    ref.invalidateSelf();
  }

  void _reschedule() {
    final subs = state.valueOrNull ?? const [];
    final enabled = ref.read(settingsProvider).notifyEnabled;
    ref.read(notificationServiceProvider).rescheduleAll(subs, enabled: enabled);
  }
}

final subscriptionsProvider =
    AsyncNotifierProvider<SubscriptionsNotifier, List<Subscription>>(
  SubscriptionsNotifier.new,
);

/// Active subscription count (used by premium limit checks).
final subscriptionCountProvider = Provider<int>((ref) {
  return ref.watch(subscriptionsProvider).valueOrNull?.length ?? 0;
});

/// The home list: filtered by "show paused" and ordered per the sort mode.
final visibleSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  final all = ref.watch(subscriptionsProvider).valueOrNull ?? const [];
  final settings = ref.watch(settingsProvider);

  var list = all.where((s) => settings.showPaused || !s.isPaused).toList();

  int byName(Subscription a, Subscription b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  switch (settings.sortMode) {
    case SortMode.manual:
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    case SortMode.priceAsc:
      list.sort((a, b) =>
          a.monthlyAmountIn(settings.mainCurrency)
              .compareTo(b.monthlyAmountIn(settings.mainCurrency)));
    case SortMode.priceDesc:
      list.sort((a, b) =>
          b.monthlyAmountIn(settings.mainCurrency)
              .compareTo(a.monthlyAmountIn(settings.mainCurrency)));
    case SortMode.nameAsc:
      list.sort(byName);
    case SortMode.nameDesc:
      list.sort((a, b) => byName(b, a));
    case SortMode.dateNear:
      list.sort((a, b) =>
          a.daysUntilNextPayment.compareTo(b.daysUntilNextPayment));
  }
  return list;
});

// ── Categories ────────────────────────────────────────────────────────────
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() =>
      ref.watch(categoryRepositoryProvider).getAll();

  Future<void> save(Category c) async {
    await ref.read(categoryRepositoryProvider).upsert(c);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(categoryRepositoryProvider).delete(id);
    ref.invalidateSelf();
    ref.invalidate(subscriptionsProvider);
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

final categoriesMapProvider = Provider<Map<String, Category>>((ref) {
  final list = ref.watch(categoriesProvider).valueOrNull ?? const [];
  return {for (final c in list) c.id: c};
});

// ── Payment methods ─────────────────────────────────────────────────────────
class PaymentMethodsNotifier extends AsyncNotifier<List<PaymentMethod>> {
  @override
  Future<List<PaymentMethod>> build() =>
      ref.watch(paymentMethodRepositoryProvider).getAll();

  Future<void> save(PaymentMethod m) async {
    await ref.read(paymentMethodRepositoryProvider).upsert(m);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(paymentMethodRepositoryProvider).delete(id);
    ref.invalidateSelf();
    ref.invalidate(subscriptionsProvider);
  }
}

final paymentMethodsProvider =
    AsyncNotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>(
  PaymentMethodsNotifier.new,
);

final paymentMethodsMapProvider = Provider<Map<String, PaymentMethod>>((ref) {
  final list = ref.watch(paymentMethodsProvider).valueOrNull ?? const [];
  return {for (final m in list) m.id: m};
});
