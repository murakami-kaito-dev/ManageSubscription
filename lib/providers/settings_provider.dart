import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/currency.dart';
import '../data/models/app_settings.dart';
import 'core_providers.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kCurrency = 'settings_currency';
  static const _kSort = 'settings_sort';
  static const _kAccent = 'settings_accent';
  static const _kShowPaused = 'settings_show_paused';
  static const _kNotify = 'settings_notify';

  @override
  AppSettings build() {
    final p = ref.watch(prefsProvider);
    return AppSettings(
      mainCurrency: AppCurrencyX.fromCode(p.getString(_kCurrency)),
      sortMode: SortMode.values.firstWhere(
        (s) => s.name == p.getString(_kSort),
        orElse: () => SortMode.manual,
      ),
      accentColorValue: p.getInt(_kAccent) ?? 0xFF6E9080,
      showPaused: p.getBool(_kShowPaused) ?? true,
      notifyEnabled: p.getBool(_kNotify) ?? true,
    );
  }

  Future<void> setCurrency(AppCurrency c) async {
    state = state.copyWith(mainCurrency: c);
    await ref.read(prefsProvider).setString(_kCurrency, c.code);
  }

  Future<void> setSortMode(SortMode s) async {
    state = state.copyWith(sortMode: s);
    await ref.read(prefsProvider).setString(_kSort, s.name);
  }

  Future<void> setAccent(int colorValue) async {
    state = state.copyWith(accentColorValue: colorValue);
    await ref.read(prefsProvider).setInt(_kAccent, colorValue);
  }

  Future<void> setShowPaused(bool v) async {
    state = state.copyWith(showPaused: v);
    await ref.read(prefsProvider).setBool(_kShowPaused, v);
  }

  Future<void> setNotifyEnabled(bool v) async {
    state = state.copyWith(notifyEnabled: v);
    await ref.read(prefsProvider).setBool(_kNotify, v);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Convenience: a formatter for the user's main currency.
final mainCurrencyFormatterProvider = Provider<CurrencyFormatter>((ref) {
  final currency = ref.watch(settingsProvider.select((s) => s.mainCurrency));
  return CurrencyFormatter(currency);
});
