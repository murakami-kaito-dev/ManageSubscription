import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency.dart';

/// How the home list is ordered. Auto-sorting is a premium feature; free users
/// stay on [manual] (drag to reorder).
enum SortMode { manual, priceAsc, priceDesc, nameAsc, nameDesc, dateNear }

extension SortModeX on SortMode {
  String get label => switch (this) {
        SortMode.manual => 'なし（手動）',
        SortMode.priceAsc => '料金が安い順',
        SortMode.priceDesc => '料金が高い順',
        SortMode.nameAsc => '名前順',
        SortMode.nameDesc => '名前順（反対）',
        SortMode.dateNear => '支払い日が近い順',
      };

  // Sorting is free for everyone.
  bool get isPremium => false;
}

/// Selectable accent colors. Only the first is free; the rest are premium.
class ThemeAccent {
  const ThemeAccent(this.name, this.color, {this.premium = true});
  final String name;
  final Color color;
  final bool premium;

  // Theme color is free for everyone.
  static const List<ThemeAccent> options = [
    ThemeAccent('セージ', AppColors.primary, premium: false),
    ThemeAccent('コーラル', AppColors.coral, premium: false),
    ThemeAccent('ダスティブルー', Color(0xFF86A9C4), premium: false),
    ThemeAccent('モーヴ', Color(0xFFC39BB4), premium: false),
    ThemeAccent('テラコッタ', Color(0xFFCE8B6A), premium: false),
    ThemeAccent('オリーブ', Color(0xFFA9B583), premium: false),
  ];
}

@immutable
class AppSettings {
  const AppSettings({
    this.mainCurrency = AppCurrency.jpy,
    this.sortMode = SortMode.manual,
    this.accentColorValue = 0xFF6E9080,
    this.showPaused = true,
    this.alwaysShowDetails = false,
  });

  final AppCurrency mainCurrency;
  final SortMode sortMode;
  final int accentColorValue;
  final bool showPaused;

  /// When true, the subscription form's "詳細設定" section starts expanded.
  final bool alwaysShowDetails;

  Color get accent => Color(accentColorValue);

  AppSettings copyWith({
    AppCurrency? mainCurrency,
    SortMode? sortMode,
    int? accentColorValue,
    bool? showPaused,
    bool? alwaysShowDetails,
  }) =>
      AppSettings(
        mainCurrency: mainCurrency ?? this.mainCurrency,
        sortMode: sortMode ?? this.sortMode,
        accentColorValue: accentColorValue ?? this.accentColorValue,
        showPaused: showPaused ?? this.showPaused,
        alwaysShowDetails: alwaysShowDetails ?? this.alwaysShowDetails,
      );
}
