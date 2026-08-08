# CLAUDE.md — プロジェクト運用ルール

「サブスク家計簿」（`com.submana.app` / Android `com.example.manage_subscription`、
repo: github.com/murakami-kaito-dev/ManageSubscription）。Flutter 単一コードベース、UI は日本語固定。
このファイルは**毎セッション自動で読み込まれる恒久ルール**。ユーザーが毎回指示しなくても以下を守ること。

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
- **こまめに、意味の分かるメッセージでコミット**する。デフォルトブランチ直コミットは避け、必要なら先にブランチを切る。
- コミットメッセージの末尾に必ず付与:
  ```
  Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
  ```
- push はユーザーに言われたときだけ。

## 秘密情報（コミット禁止・.gitignore 済み）
- `ios/AuthKey_*.p8`、`ios/AppStoreConnect*.json` などの資格情報は**絶対にコミット/共有しない**。

## 開発コマンド
- 全解放ビルド: `flutter run --dart-define=DEV_UNLOCK=true`（`kDevUnlockAll`）
- クリーン再インストール手順は [.claude/docs/README.md](.claude/docs/README.md)。
