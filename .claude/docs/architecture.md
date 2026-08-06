# アーキテクチャ

## 技術スタック
- **Flutter**（Dart）。iOS/Android。UI は `Locale('ja')` 固定
- **Riverpod**（flutter_riverpod）— 状態管理
- **sqflite** — サブスク/カテゴリ/支払い方法の永続化
- **SharedPreferences** — 設定・フラグ（試用開始日、通知ON/OFF、テーマ色、レビュー表示済み等）
- 主なパッケージ: fl_chart（グラフ）, table_calendar（カレンダー）, flutter_local_notifications ＋ flutter_timezone（通知）, image_picker ＋ image_cropper（アイコン画像）, file_picker（CSV選択）, csv（CSV入出力）, share_plus（共有）, purchases_flutter（RevenueCat）, in_app_review（評価）, http（為替・フィードバック）, url_launcher（規約/ポリシー）

## レイヤ構成（`lib/`）
- `main.dart` — 起動時初期化（DB/prefs/画像パス/為替/購入/通知の順）、`ProviderScope` overrides
- `app.dart` — `MaterialApp`。テーマ・日本語ローカライズ。`builder` で `ForegroundReminderHost` を全画面の上に被せる。`home: HomeShell`
- `core/` — テーマ（`app_colors`/`AppAccent`/`app_typography`/`app_spacing`/`app_shadows`）、`utils/`（billing・currency・amount_input・image_paths・dates・text_input）、`monetization/iap.dart`、`store_links.dart`、`legal.dart`、`premium_limits.dart`、`dev_config.dart`、共通 `widgets/`
- `data/` — `database/app_database.dart`（スキーマ+シード）、`models/`、`repositories/`
- `providers/` — `core_providers`（DB/prefs/サービス）、`subscription_providers`、`analytics_providers`、`settings_provider`、`premium_provider`
- `features/` — 画面ごと（home / analytics / calendar / history / settings / premium / rating / notifications / shell）
- `services/` — ads / csv / currency / image / notifications / purchases / rating

## 主要 Provider（この名前で参照される）
- `databaseProvider` / `prefsProvider` / `purchaseServiceProvider` — main() で override
- `subscriptionsProvider`（`AsyncNotifier<List<Subscription>>`）: `.save` / `.saveAll` / `.delete` / `.setPaused` / `.reorder`
- `visibleSubscriptionsProvider` — 表示用（停止中フィルタ＋並べ替え）
- `subscriptionCountProvider`
- `categoriesProvider` / `paymentMethodsProvider` と `…MapProvider`（id→エンティティ）
- `analyticsProvider(AnalyticsQuery)` / `analyticsMembersProvider` / `monthlyHistoryProvider` / `yearlyHistoryProvider` / `monthPaymentsProvider` / `yearSubscriptionTotalsProvider`
- `settingsProvider`（`Notifier<AppSettings>`）— 通貨/テーマ色/通知ON/表示設定/並べ替え/停止表示
- `premiumProvider`（bool = 有料 or 試用中 or dev）/ `entitlementProvider`（プラン+試用残日数）
- サービス: `notificationServiceProvider` / `csvExportServiceProvider` / `csvImportServiceProvider` / `imagePickerServiceProvider` / `ratingServiceProvider` / `adServiceProvider`

## テーマ
- `AppAccent`（primary/deep/soft）はユーザー選択のテーマ色から算出。`AppAccent.of(context)` で参照
- サブスクのアイコン/円グラフ等は**各アイテム固有の色**（`sub.color`）を使用（テーマ色ではない）
- claymorphism（`SoftCard` / `SoftButton` / `SoftHeader` / `Pressable` / 影）

## エラー耐性の原則
- 金額など非有限値（Infinity/NaN）は表示側（`CurrencyFormatter`・ドーナツ・`FittedBox`）でフォールバック
- CSV は「解析→プレビュー→確定」で、不正行はスキップ。DB破壊はしない
- 日付計算は fast-forward で長スパンでも正確（[billing.md](billing.md)）
