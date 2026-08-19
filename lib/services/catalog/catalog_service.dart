import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/quick_add_catalog.dart';

/// クイック追加メニューのカタログ取得（`RatesService` と同じ作法）。
///
/// 起動時:
///   1. [loadLocal] … 前回取得した JSON（prefs）→ 無ければ同梱アセット、を
///      同期的な状態として保持（ここまでで必ずメニューは出せる）
///   2. [refresh] … 1日1回、GitHub の公開カタログを取得して差し替え・保存
///      （fire-and-forget。失敗しても 1. の内容で動き続ける）
///
/// 価格改定は `submana-catalog` リポジトリの catalog.json を push するだけで
/// 全ユーザーに反映される（アプリの更新は不要）。
class CatalogService {
  CatalogService(this._prefs);

  final SharedPreferences _prefs;

  static const _kJson = 'quick_add_catalog_json';
  static const _kDate = 'quick_add_catalog_date';

  static const bundledAsset = 'assets/quick_add/catalog.json';
  static const remoteUrl =
      'https://raw.githubusercontent.com/murakami-kaito-dev/submana-catalog/main/catalog.json';

  QuickAddCatalog? _catalog;

  /// 現在のカタログ。[loadLocal] 後は必ず非 null。
  QuickAddCatalog get catalog => _catalog!;

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// 前回取得分（無ければ同梱アセット）を読み込む。起動時に一度 await する
  /// （どちらもローカルの数KBなので起動コストは無視できる）。
  Future<void> loadLocal() async {
    final cached = _prefs.getString(_kJson);
    if (cached != null) {
      _catalog = QuickAddCatalog.tryParse(cached);
    }
    if (_catalog == null) {
      final bundled = await rootBundle.loadString(bundledAsset);
      _catalog = QuickAddCatalog.tryParse(bundled);
      // 同梱アセットは常に正であるべき。壊れていたらビルド時の不良なので
      // ここで気づけるよう assert に倒す（release では上の cached で動く）。
      assert(_catalog != null, 'bundled catalog.json is invalid');
    }
  }

  /// ネットワークから最新カタログを取得して差し替える。1日1回だけ。
  /// best-effort — 失敗しても何も壊さない。
  Future<void> refresh() async {
    if (_prefs.getString(_kDate) == _today) return; // 今日はもう取得済み
    try {
      final res = await http
          .get(Uri.parse(remoteUrl))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return;
      final parsed = QuickAddCatalog.tryParse(res.body);
      if (parsed == null) return; // 形式不正は無視（前回値を維持）
      _catalog = parsed;
      await _prefs.setString(_kJson, res.body);
      await _prefs.setString(_kDate, _today);
    } catch (e) {
      debugPrint('catalog refresh skipped: $e');
    }
  }
}
