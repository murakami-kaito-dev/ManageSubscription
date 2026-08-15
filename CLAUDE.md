# CLAUDE.md — プロジェクト運用ルール

「サブスク家計簿」（`com.submana.app` / Android `com.example.manage_subscription`、
repo: github.com/murakami-kaito-dev/ManageSubscription）。Flutter 単一コードベース、UI は日本語固定。
このファイルは**毎セッション自動で読み込まれる恒久ルール**。ユーザーが毎回指示しなくても以下を守ること。

## 情報のありか（新規セッションの初動でまず把握する地図）
このプロジェクトの全体像は下記を辿れば掴める（＝新規参画時に見る順番）：
- **このファイル `CLAUDE.md`** … 固有ルール・不変条件・品質ゲート・禁忌
- **ドキュメント索引** [.claude/docs/README.md](.claude/docs/README.md)（アーキテクチャ/画面/データ/課金/通知 等の入口）
- **リリース履歴** [.claude/docs/release-log.md](.claude/docs/release-log.md)（どのビルドで何を出したか・状態）
- **`.claude/rules/`**（パス限定ルール。例: `lib/**/*.dart` の Riverpod 設計）／**プロジェクト Skill** `app-store-release`（このアプリのストア配信）
- **自動メモリ**（`~/.claude/projects/<repo>/memory/`）… これまでの経緯・決定・学び
- Claude 運用の共通ルール（Git・秘密・タグ・記録・越境禁止など）は **グローバル `~/.claude/CLAUDE.md`** と各 Skill を参照

## ドキュメント
- ドキュメントの置き場は **`.claude/docs/` だけ**。ここ以外に仕様書・READMEを作らない。
- **実装・修正をしたら、必ず関連ドキュメントも同じ変更で更新する**（後回しにしない）。
  主な対応: 画面→[.claude/docs/screens.md](.claude/docs/screens.md)、DB/モデル/上限→[data-model.md](.claude/docs/data-model.md)、
  Provider/レイヤ/起動→[architecture.md](.claude/docs/architecture.md)、CSV→[csv-import.md](.claude/docs/csv-import.md)、
  課金→[monetization.md](.claude/docs/monetization.md)、通知→[notifications.md](.claude/docs/notifications.md)。
- 索引・概要は [.claude/docs/README.md](.claude/docs/README.md)。

## コード品質（マージ前に必須）
- **`flutter analyze` は常に 0 issues** を維持する（info も潰す）。
- **`flutter test` は常にグリーン**。ロジックを変えたらテストも足す/直す。
- 周辺コードの命名・コメント密度・スタイルに合わせる（claymorphism: `SoftCard`/`SoftButton`/`SoftHeader`/`Pressable`）。

## リリース前チェックリスト（禁忌事項・毎回必ず確認）
配信（Release）ビルドを作る前に、以下の3点を**毎回必ず**確認する。1つでも欠けたらリリースしない。
1. **サブスク購入が実機/サンドボックスで正常に完了できること。** 購入ボタンで OS 決済シートが出て、
   購入後に `premium` エンタイトルメントが有効化されること。「決済シートが出ない／エラーで終わる」状態を放置しない。
   （購入経路は `PurchaseService.purchase` → RevenueCat。全オファリング横断＋商品直接購入のフォールバックあり。）
2. **デバッグ機能がリリースビルドに含まれていないこと。** 設定画面のバージョン長押しによるプレミアム切替
   （`debugToggle`/`debugSetPremium`）などのデバッグ導線は `kDebugMode` ガードで Release から完全に除外する
   （一般ユーザーがプレミアムを不正に有効化できてはならない）。
3. **シェア機能に正しい App Store リンクが含まれていること。** `StoreLinks.appStoreId` が実際の App Store ID
   （現行 `6799400490`）で、`StoreLinks.shareUrl()` が有効な App Store URL を返すこと。空文字のまま出荷しない。

## データ・マイグレーション方針
- 出荷済みのデータ形状を変えるときだけ `AppDatabase` に `onUpgrade` を追加する。
  **未リリース（既存インストールなし）の間はマイグレーション不要**——スキーマは直接変えてよい。
- 主要な不変条件（`.claude/docs/data-model.md` と同期させる）:
  - 金額 0〜1億（`kMaxAmount`）
  - サブスク総数 **100件**（`PremiumLimits.hardMaxSubscriptions`、全ユーザー共通のハード上限・サイレント制限）
  - 初回支払日 2000〜2100 年 / custom interval 1〜999
- アイコン画像は**ファイル名のみ**保存（`ImagePaths`）。絶対パス保存は禁止。

## 起動パフォーマンス
- **重い O(件数) 処理を `runApp` の前で await しない**。通知の再スケジュールは `main.dart` で
  fire-and-forget にしてある（理由と全体像は [architecture.md](.claude/docs/architecture.md) の「起動コストとスケール」）。

## Git / コミット
- Git 運用は**個人共通ルール（`~/.claude/CLAUDE.md`）と `git-workflow` スキルに従う**。
  （要点：ソロ開発なので通常は `main` 直コミット可／commit・push は指示されたときだけ／
  コミット末尾に `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`／秘密はコミット禁止・
  `git commit` 前にグローバルフックでも機械ブロック／節目で `vX.Y.Z` タグ。）
- **このプロジェクト固有の補足**は下記「秘密情報」を参照。

## 秘密情報（このプロジェクト固有・コミット禁止・.gitignore 済み）
- `ios/AuthKey_*.p8`（ASC APIキー）、`ios/AppStoreConnect*.json`、`ios/SubscriptionKey_*.p8`
  （RevenueCat用 In-App Purchase Key）、`ios/*Issuer*.json` などの資格情報は**絶対にコミット/共有・中身を読まない**。

## 開発コマンド
- 全解放ビルド: `flutter run --dart-define=DEV_UNLOCK=true`（`kDevUnlockAll`）
- クリーン再インストール手順は [.claude/docs/README.md](.claude/docs/README.md)。
