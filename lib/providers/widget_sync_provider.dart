import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/widget/widget_bridge.dart';
import '../services/widget/widget_payload.dart';
import 'settings_provider.dart';
import 'subscription_providers.dart';

/// サブスク一覧・メイン通貨の変化をホーム画面ウィジェットへ反映する。
///
/// ルートで `ref.watch(widgetSyncProvider)` するだけで有効になる。
/// `fireImmediately: true` により起動直後にも一度 push するので、
/// 為替（起動時に取得）を反映した最新の換算額がウィジェットに載る。
final widgetSyncProvider = Provider<void>((ref) {
  void push() {
    final subs = ref.read(subscriptionsProvider).valueOrNull;
    if (subs == null) return; // まだロード中。ロード完了時の listen で push される。
    final settings = ref.read(settingsProvider);
    WidgetBridge.update(buildWidgetPayload(subs, settings.mainCurrency,
        accentArgb: settings.accentColorValue));
  }

  ref.listen(subscriptionsProvider, (_, __) => push(), fireImmediately: true);
  ref.listen(settingsProvider.select((s) => s.mainCurrency), (_, __) => push());
  ref.listen(
      settingsProvider.select((s) => s.accentColorValue), (_, __) => push());
});
