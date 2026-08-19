import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/features/subscription/widgets/quick_add_sheet.dart';
import 'package:manage_subscription/providers/core_providers.dart';
import 'package:manage_subscription/services/catalog/catalog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// クイック追加シートの骨格:
/// - カタログのサービス・固定費がタイルとして並ぶ
/// - 一覧に無いもの向けの「手入力する」導線が必ずある
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('タイルと「手入力する」導線が表示される', (tester) async {
    // シート内リストは遅延構築なので、縦長の画面にして全セクションを一度に
    // 可視化する（モーダルシート上のドラッグはシート自体に吸われて不安定なため）。
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final svc = CatalogService(await SharedPreferences.getInstance());
    await svc.loadLocal();

    await tester.pumpWidget(ProviderScope(
      overrides: [catalogServiceProvider.overrideWithValue(svc)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showQuickAddSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('かんたん追加'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('固定費'), findsOneWidget);
    expect(find.text('家賃'), findsOneWidget);
    expect(find.textContaining('手入力する'), findsOneWidget);
  });
}
