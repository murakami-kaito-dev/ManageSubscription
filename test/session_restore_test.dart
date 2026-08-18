import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/providers/session_restore_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// セッション復元（jetsam 対策）の仕様:
/// - 30分（freshWindow）以内の再起動でだけタブ・下書きを復元する
/// - 鮮度切れの下書きは読み出し時に破棄される
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SessionRestore> make({DateTime Function()? now}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return SessionRestore(prefs, now: now);
  }

  test('鮮度内ならタブを復元し、鮮度切れならホーム(0)に戻る', () async {
    var now = DateTime(2026, 8, 18, 12, 0);
    final r = await make(now: () => now);
    await r.saveTab(3);
    expect(r.restoredTab(), 3);

    now = now.add(const Duration(minutes: 29));
    expect(r.restoredTab(), 3, reason: '29分後はまだ復元する');

    now = now.add(const Duration(minutes: 2));
    expect(r.restoredTab(), 0, reason: '31分後は別セッション扱い');
  });

  test('範囲外のタブ番号は 0 に丸める', () async {
    final r = await make();
    await r.saveTab(9);
    expect(r.restoredTab(tabCount: 5), 0);
  });

  test('下書きは鮮度内なら往復し、鮮度切れなら破棄される', () async {
    var now = DateTime(2026, 8, 18, 12, 0);
    final r = await make(now: () => now);
    await r.saveDraft({'name': 'Netflix', 'colorValue': 123});

    final d = r.readDraft();
    expect(d, isNotNull);
    expect(d!['name'], 'Netflix');
    expect(d['colorValue'], 123);

    now = now.add(const Duration(hours: 1));
    expect(r.readDraft(), isNull, reason: '1時間後は復元しない');
    now = now.subtract(const Duration(hours: 1));
    expect(r.readDraft(), isNull, reason: '鮮度切れ時に破棄済み');
  });

  test('clearDraft で消える', () async {
    final r = await make();
    await r.saveDraft({'name': 'x'});
    await r.clearDraft();
    expect(r.readDraft(), isNull);
  });

  test('壊れた下書きJSONは無視して破棄する', () async {
    SharedPreferences.setMockInitialValues({
      'restore_draft': '{broken json',
      'restore_stamp': DateTime.now().millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();
    final r = SessionRestore(prefs);
    expect(r.readDraft(), isNull);
  });
}
