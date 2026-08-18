import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core_providers.dart';

/// iOS がバックグラウンドのアプリをメモリ圧力で終了（jetsam）しても、
/// 「最後に開いていたタブ」と「編集途中の入力（下書き）」に自動復帰するための
/// 軽量なセッション復元。
///
/// - 保存先は SharedPreferences（`restore_*` キー）
/// - **鮮度窓**: 最後の記録から [freshWindow] 以内の再起動でだけ復元する。
///   翌日の通常起動などでは復元せず、いつも通りホームから始まる。
/// - 下書きはアプリが背面に回った瞬間（[AppLifecycleState.paused] 等）に
///   フォーム側が保存する（kill は背面でしか起きないので、それで十分）。
class SessionRestore {
  SessionRestore(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static const _kTab = 'restore_tab';
  static const _kStamp = 'restore_stamp';
  static const _kDraft = 'restore_draft';

  /// これより古い記録は「別のセッション」とみなして復元しない。
  static const freshWindow = Duration(minutes: 30);

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  bool get _isFresh {
    final ms = _prefs.getInt(_kStamp);
    if (ms == null) return false;
    final age = _now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    return age >= Duration.zero && age <= freshWindow;
  }

  /// 記録の鮮度を今に更新する（アプリが背面に回るときにも呼ぶ）。
  Future<void> stampNow() =>
      _prefs.setInt(_kStamp, _now().millisecondsSinceEpoch);

  // ── タブ ────────────────────────────────────────────────────────────────
  Future<void> saveTab(int index) async {
    await _prefs.setInt(_kTab, index);
    await stampNow();
  }

  /// 起動時に開くタブ。鮮度切れなら 0（ホーム）。
  int restoredTab({int tabCount = 5}) {
    if (!_isFresh) return 0;
    final i = _prefs.getInt(_kTab) ?? 0;
    return (i >= 0 && i < tabCount) ? i : 0;
  }

  // ── 編集フォームの下書き ────────────────────────────────────────────────
  Future<void> saveDraft(Map<String, dynamic> draft) async {
    await _prefs.setString(_kDraft, jsonEncode(draft));
    await stampNow();
  }

  /// 復元対象の下書き。鮮度切れ・無しなら null（切れていたら消しておく）。
  Map<String, dynamic>? readDraft() {
    final raw = _prefs.getString(_kDraft);
    if (raw == null) return null;
    if (!_isFresh) {
      _prefs.remove(_kDraft);
      return null;
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _prefs.remove(_kDraft);
      return null;
    }
  }

  Future<void> clearDraft() => _prefs.remove(_kDraft);
}

final sessionRestoreProvider = Provider<SessionRestore>(
  (ref) => SessionRestore(ref.watch(prefsProvider)),
);
