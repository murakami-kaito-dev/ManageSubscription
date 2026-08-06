# サブスク家計簿 — 仕様ドキュメント

このフォルダは、ソースコードを読まなくても仕様が把握できることを目的とした
最新状態の仕様書です。実装を変更したら該当ドキュメントも更新してください。

## アプリ概要
- 名称: **サブスク家計簿**（Bundle ID `com.submana.app`）
- 目的: 契約中のサブスク（定額サービス）の支払いを記録・可視化し、固定費を節約する
- 対象: iOS / Android（Flutter 単一コードベース）。UI は日本語固定

## 目次
- [architecture.md](architecture.md) — 技術スタック・レイヤ構成・主要 Provider・テーマ
- [data-model.md](data-model.md) — DB スキーマとモデル（Subscription / Category / PaymentMethod / NotifyRule / 設定）
- [billing.md](billing.md) — 支払いサイクルと日付計算のルール
- [screens.md](screens.md) — 各画面の定義・仕様（ホーム/分析/カレンダー/履歴/設定/新規編集/ペイウォール ほか）
- [csv-import.md](csv-import.md) — CSV エクスポート/インポートの書式・バリデーション・ヘルプ
- [monetization.md](monetization.md) — 料金プラン・無料体験・課金（RevenueCat）
- [notifications.md](notifications.md) — 通知（OS ローカル通知＋アプリ内バナー）
- [rating-share.md](rating-share.md) — アプリ評価・レビュー誘導・共有

## 開発の要点（すぐ効く前提）
- 状態管理: **Riverpod**（`NotifierProvider` / `Provider.family` / `ConsumerWidget`）
- 永続化: **sqflite**（`AppDatabase`、`onUpgrade` マイグレーション）＋ `SharedPreferences`
- 開発者アンロック: `--dart-define=DEV_UNLOCK=true` で全機能解放（`kDevUnlockAll`）
- クリーン再インストール: `scripts/fresh_install.sh`
- 金額上限: 1アイテム **¥100,000,000（1億）**（`kMaxAmount`）
