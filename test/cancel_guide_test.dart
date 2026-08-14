import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_subscription/features/cancellation/cancel_guide_data.dart';
import 'package:manage_subscription/features/cancellation/cancel_guide_screen.dart';

/// 解約ガイドは静的なリンク集なので、壊れるとしたら「データの形」。
/// URL が https で開ける形か・重複や空欄がないか・全カテゴリーに中身があるかを見る
/// （リンク先が生きているかは実際に開いて確認するしかないので、ここでは見ない）。
void main() {
  test('ids are unique', () {
    final ids = kCancelGuideEntries.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every entry has a launchable https url and non-empty texts', () {
    for (final e in kCancelGuideEntries) {
      final uri = Uri.tryParse(e.url);
      expect(uri, isNotNull, reason: '${e.id}: URL をパースできない');
      expect(uri!.scheme, 'https', reason: '${e.id}: https でない');
      expect(uri.host, isNotEmpty, reason: '${e.id}: ホストが空');
      expect(e.name.trim(), isNotEmpty, reason: '${e.id}: 表示名が空');
      expect(e.route.trim(), isNotEmpty, reason: '${e.id}: 解約導線の説明が空');
      expect(e.caution?.trim(), isNot(''), reason: '${e.id}: 注意書きが空文字');
    }
  });

  test('every category has at least one entry', () {
    for (final section in cancelGuideSections()) {
      expect(section.entries, isNotEmpty,
          reason: '${section.category.label} が空セクション');
    }
    // セクションの合計＝全件（取りこぼしなし）。
    final total = cancelGuideSections()
        .fold<int>(0, (sum, s) => sum + s.entries.length);
    expect(total, kCancelGuideEntries.length);
  });

  test('this app is listed too (自分の解約方法も隠さない)', () {
    final mine = kCancelGuideEntries
        .where((e) => e.category == CancelCategory.thisApp)
        .toList();
    expect(mine, isNotEmpty);
    expect(mine.first.url, kAppStoreSubscriptionsUrl);
  });

  test('app-store / play entries point at the OS subscription pages', () {
    final byId = {for (final e in kCancelGuideEntries) e.id: e};
    expect(byId['app_store']!.url, kAppStoreSubscriptionsUrl);
    expect(byId['google_play']!.url, kGooglePlaySubscriptionsUrl);
  });

  group('search', () {
    test('empty query returns everything', () {
      expect(searchCancelGuide('   '), kCancelGuideEntries);
    });

    test('matches on name, case-insensitively', () {
      final hits = searchCancelGuide('netflix');
      expect(hits.map((e) => e.id), contains('netflix'));
    });

    test('matches on kana aliases', () {
      final hits = searchCancelGuide('ネットフリックス');
      expect(hits.map((e) => e.id), contains('netflix'));
    });

    test('unknown service returns no hits', () {
      expect(searchCancelGuide('存在しないサービス名'), isEmpty);
    });
  });

  group('CancelGuideScreen', () {
    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        const MaterialApp(home: CancelGuideScreen()));

    testWidgets('shows the sections and never promises in-app cancellation',
        (tester) async {
      await pump(tester);
      expect(find.text('解約方法'), findsOneWidget);
      expect(find.text('公式の解約ページを開きます'), findsOneWidget);
      expect(find.text(CancelCategory.platform.label), findsOneWidget);
      expect(find.text('App Store で登録したサブスク'), findsOneWidget);
    });

    testWidgets('search narrows the list to the matching service',
        (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'ネットフリックス');
      await tester.pump();
      expect(find.text('検索結果（1件）'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Spotify'), findsNothing);
    });

    testWidgets('tapping a service opens the sheet with the official-page CTA',
        (tester) async {
      await pump(tester);
      // カナで検索して、検索欄の文字列自体がヒットしないようにする。
      await tester.enterText(find.byType(TextField), 'ネットフリックス');
      await tester.pump();
      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();
      expect(find.text('どこから解約するか'), findsOneWidget);
      expect(find.text('公式の解約ページを開く'), findsOneWidget);
      expect(find.text('ブラウザで公式ページを開きます。このアプリからは解約できません。'), findsOneWidget);
    });
  });
}
