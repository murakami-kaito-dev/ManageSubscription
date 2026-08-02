# サブスク管理 (Manage Subscription)

端末内で完結する、サブスクリプション管理アプリ。毎月の支払いを「見える化」し、
無駄遣いへの気づきを与えることを目的としています。

デザインは参考画像の「白基調フラットUI」とは意図的に異なる、**エレガント・ソフトUI /
クレイモーフィズム**。温かみのあるオフホワイトのキャンバスに、柔らかな二重シャドウで
浮き上がるクッションのようなカードを重ねています。アクセントは落ち着いたセージグリーン
とコーラル。

## 主な機能

| 画面 | 内容 |
| --- | --- |
| ホーム | サブスク一覧・支払いプログレスバー・今月の合計・新規追加(FAB)・手動並べ替え |
| 分析 | fl_chart のドーナツチャート／月間・年間切替／コスパ一覧 |
| カレンダー | table_calendar による月間表示・日別の支払い |
| 支払い履歴 | fl_chart の棒グラフによる12ヶ月推移・月別ドリルダウン |
| 設定 | 通貨・テーマカラー・通知・CSVエクスポート・カテゴリー/支払い方法管理 |
| プレミアム | 機能比較表・課金導線・購入時のセレブレーション演出 |

### オリジナル機能: サブスク・コスパチェッカー
各サブスクに「月の推定利用回数」を入力すると、月額 ÷ 利用回数で
**「1回あたりの単価」** を自動計算。分析画面と入力画面でリアルタイムに表示し、
費用対効果を可視化します（お得／ふつう／割高かも の判定つき）。

## 無料版の制限（プレミアムで解除）
- サブスク登録: 8件 / カテゴリー: 3件 / 支払い方法: 3件 / 通知設定: 1件
- 広告バナー表示、画像登録不可、CSV不可、自動並べ替え不可、テーマカラー変更不可
- 分析のカテゴリ別/支払い方法別、カレンダー・履歴の全期間閲覧はプレミアムのみ

制限の定義は [`lib/core/premium_limits.dart`](lib/core/premium_limits.dart) に集約。

## 技術スタック
- Flutter / Dart, 状態管理: **flutter_riverpod**
- ローカルDB: **sqflite**（端末内完結・ネットワーク不要）
- チャート: **fl_chart** / カレンダー: **table_calendar**
- 広告: **google_mobile_ads** / 課金: **purchases_flutter (RevenueCat)**
- 通知: **flutter_local_notifications** / 書き出し: **csv + share_plus**
- フォント: google_fonts（M PLUS Rounded 1c / Zen Kaku Gothic New）

## アーキテクチャ
feature-first + 3層。依存方向は `features → providers → data → core` の一方向。
詳細は `.claude/skills/riverpod-architecture/SKILL.md` を参照。

```
lib/
  core/       テーマ・共通Widget・ユーティリティ・プレミアム制限
  data/       models(immutable) / database(sqflite) / repositories
  providers/  Riverpod（subscriptions / settings / premium / analytics）
  services/   ads / purchases / notifications / csv
  features/   home / analytics / calendar / history / settings / premium / shell
```

## セットアップ
```bash
flutter pub get
flutter run
```

### 課金 (RevenueCat)
デフォルトはキー不要で動作する**モック実装**（購入すると即プレミアム付与、設定画面の
バージョン番号を長押しで ON/OFF 切替）。本番化する場合は
[`lib/services/purchases/purchase_service.dart`](lib/services/purchases/purchase_service.dart)
の `useRevenueCat = true` にし、APIキーと entitlement ID を設定してください。

### 広告 (AdMob)
Google の**テスト用広告ユニットID**で動作します。本番前に
`lib/services/ads/ad_service.dart` と各プラットフォームの App ID
（`AndroidManifest.xml` / `Info.plist`）を差し替えてください。

> 注: 広告・課金・通知の初期化はいずれも best-effort。キー未設定でもアプリは
> 全画面クラッシュせずに動作します。
