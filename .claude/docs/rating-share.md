# アプリ評価・レビュー誘導・共有

## ストアリンク（`core/store_links.dart`）
- `appStoreId`（数値のApple ID）: **未公開のため空（TODO）**。埋めると iOS 用URLが有効化
- `androidPackage`: `applicationId`（現 `com.example.manage_subscription`）
- `iosUrl`（ID未設定時 null）/ `androidUrl` / `currentPlatformUrl` / `shareLinks()`

## 評価メニュー（`services/rating/rating_service.dart`）
- 設定「アプリ」セクションの **「このアプリを応援する」** → `RatingService.rate()`
- `rate()`: ネイティブ In-App Review（`in_app_review`）を優先、不可なら store listing。best-effort（例外を握る）

## レビュー誘導ポップアップ（`features/rating/rating_prompt.dart`）
- **表示条件**: ユーザーが**初めて自分でサブスクを新規追加した直後の1回のみ**（シードは対象外）。`rating_first_add_prompt_shown` フラグで一度きり
- トリガ: `SubscriptionFormScreen._save()` の新規作成成功後
- UI（ネイティブ風）: アプリ風アイコン、「「サブスク家計簿」はいかがですか？」、星タップで評価（`rate()`）、「コメントを書く」→フィードバックフォーム、「今はしない」→閉じる（スキップ可）

## 共有（設定「シェア」）
`Share.share('…\n${StoreLinks.shareLinks()}')` — 受信側OS不明のため既知のストアURLを併記（App Store は `appStoreId` 設定後に含まれる）。
