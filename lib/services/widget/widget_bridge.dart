import 'dart:io';

import 'package:flutter/services.dart';

/// ホーム画面ウィジェット（iOS WidgetKit）へのブリッジ。
///
/// App Group の UserDefaults にペイロードを書き、WidgetKit にリロードを
/// 依頼するだけの薄い層。ネイティブ実装は `ios/Runner/AppDelegate.swift`。
/// 専用パッケージは使わない（このアプリは依存を最小に保つ方針）。
class WidgetBridge {
  WidgetBridge._();

  static const _channel = MethodChannel('submana/widget');

  /// アプリとウィジェットで共有する App Group。
  /// `ios/Runner/Runner.entitlements` / `SubmanaWidget.entitlements` と一致させる。
  static const appGroupId = 'group.com.submana.app';

  /// ウィジェット側 (`SubmanaWidget.swift`) の kind と一致させる。
  static const widgetKind = 'SubmanaWidget';

  /// ペイロードを保存してウィジェットを更新する。best-effort（失敗しても
  /// アプリ本体の動作には影響させない）。iOS 以外では何もしない。
  static Future<void> update(String payloadJson) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('update', {
        'group': appGroupId,
        'kind': widgetKind,
        'payload': payloadJson,
      });
    } catch (_) {/* widget update is never critical */}
  }
}
