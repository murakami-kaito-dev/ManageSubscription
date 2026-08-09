# App Store スクリーンショット（6.9インチ / iPhone 16 Pro Max）

App Store Connect 掲載用のスクリーンショット。**1320×2868 px**、ステータスバーは
すべて **9:41 / フル電波・Wi-Fi・満充電** に統一。

| ファイル | 画面 |
|---|---|
| `6.9inch/01-home.png` | ホーム（今月の合計＋サブスク一覧） |
| `6.9inch/02-analytics.png` | 分析（ドーナツグラフ＋内訳） |
| `6.9inch/03-calendar.png` | カレンダー（支払日ドット表示） |
| `6.9inch/04-history.png` | 支払い履歴（月別棒グラフ） |
| `6.9inch/05-premium.png` | プレミアム（無料プラン→2週間無料の訴求） |
| `6.9inch/06-settings.png` | 設定（通貨・テーマ・CSV入出力）※予備 |

App Store には 01〜05 を掲載。

## 再現方法（一時ハーネス）
撮影は使い捨ての「スクショハーネス」で行い、撮影後にコードは元へ戻している
（`git` 差分はこの `store/` のみ）。手順:

1. デモデータを増量（`app_database.dart` の `_seed` の `demos`）、初期画面を
   `--dart-define=SHOT=<home|analytics|calendar|history|premium|settings>` で切替、
   通知許可ダイアログとStoreKitを避けるため `--dart-define=SHOT_MODE=true`
   （¥フォールバック価格を表示）。プレミアムは訴求状態にするため `DEV_UNLOCK` は付けない。
2. `xcrun simctl status_bar <UDID> override --time 9:41 --batteryState charged ...`
3. `flutter build ios --debug --simulator ...` → `simctl install/launch` → `simctl io screenshot`
4. 撮影後、ハーネスのコード変更を revert（`git checkout -- lib/...`）。
