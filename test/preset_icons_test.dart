import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/core/utils/preset_icons.dart';
import 'package:manage_subscription/features/cancellation/cancel_guide_data.dart';

/// プリセットアイコンの参照スキーム（preset:<id>）と、
/// 「解約方法」収録サービスとアセットの 1:1 対応を守る。
void main() {
  group('PresetIcons', () {
    test('preset:<id> を判定・アセットパスに変換できる', () {
      expect(PresetIcons.isPreset('preset:netflix'), isTrue);
      expect(PresetIcons.isPreset('abc123.png'), isFalse);
      expect(PresetIcons.isPreset(null), isFalse);
      expect(PresetIcons.assetOf('preset:netflix'),
          'assets/preset_icons/netflix.svg');
      expect(PresetIcons.assetOf('photo.png'), isNull);
      expect(PresetIcons.assetOf('preset:'), isNull);
      expect(PresetIcons.keyFor('spotify'), 'preset:spotify');
    });
  });

  test('解約ガイドの全サービスにプリセットSVGが存在する（追加漏れ防止）', () {
    for (final e in kCancelGuideEntries) {
      final f = File('assets/preset_icons/${e.id}.svg');
      expect(f.existsSync(), isTrue,
          reason: '${e.id}: assets/preset_icons/${e.id}.svg が無い。'
              'tool/gen_preset_icons.py に追加して再生成すること');
    }
  });
}
