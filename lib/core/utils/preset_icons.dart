/// プリセットアイコン（`assets/preset_icons/*.svg`）の参照ヘルパー。
///
/// サブスクの `imagePath` は従来「ユーザー画像のファイル名のみ」を保存するが、
/// プリセットを選んだ場合は **`preset:<id>`**（例: `preset:netflix`）を保存する。
/// ファイルシステムを一切触らないので、再インストールや機種変更でも壊れない。
///
/// id は「解約方法」タブの `CancelGuideEntry.id` と 1:1 に対応し、
/// アセットは `tool/gen_preset_icons.py` が生成する。
class PresetIcons {
  PresetIcons._();

  static const prefix = 'preset:';

  /// 保存値がプリセット参照かどうか。
  static bool isPreset(String? stored) =>
      stored != null && stored.startsWith(prefix);

  /// `preset:netflix` → `assets/preset_icons/netflix.svg`。非プリセットなら null。
  static String? assetOf(String? stored) {
    if (!isPreset(stored)) return null;
    final id = stored!.substring(prefix.length);
    if (id.isEmpty) return null;
    return 'assets/preset_icons/$id.svg';
  }

  /// id から保存値を作る。
  static String keyFor(String id) => '$prefix$id';
}
