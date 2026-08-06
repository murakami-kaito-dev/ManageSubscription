# テスト計画

修正内容が**正常系・異常系**ともに問題なく動くことを確認するための資料。

- 帳票（表形式のテストケース一覧）: **[test_cases.xlsx](test_cases.xlsx)**（Excel、26ケース／概要シート＋テストケースシート）
- 自動テスト: `flutter test`
- CSV サンプル: `test/fixtures/csv/`（自動テストにも手動テストにも使用）

## 自動テスト（`flutter test`）
| ファイル | 対象 |
|---|---|
| `test/logic_test.dart` | Recurrence 換算・支払日・コスパ・プレミアム制限 |
| `test/amount_input_test.dart` | 金額の3桁カンマ整形・9桁上限・非有限ガード |
| `test/billing_longspan_test.dart` | 古いanchor＋短周期の長期スパン（fast-forward） |
| `test/foreground_reminder_test.dart` | アプリ内通知の発火時刻算出 |
| `test/gauge_render_test.dart` | ホームゲージが幅・高さともに描画される |
| `test/monetization_test.dart` | 無料体験14日・期限切れ・購入(モック) |
| `test/csv_import_test.dart` | CSVパースの単体（必須列・巨大額・日付範囲・カスタム回数・エラーグルーピング） |
| `test/csv_fixtures_test.dart` | `test/fixtures/csv/` の各サンプルを解析し結果を検証 |

## CSV サンプル（手動テスト手順）
1. `test/fixtures/csv/*.csv` を端末に送る（AirDrop / メール / ファイル）
2. アプリ: 設定 → **CSVから読み込み** → ファイル選択
3. プレビューが下表の期待どおりか確認 → 取り込む

| ファイル | 期待 |
|---|---|
| `01_valid_all_columns.csv` | 5件すべて取込・スキップ0 |
| `02_mixed_valid_and_errors.csv` | 正常3・スキップ2（通貨/周期不正が枠で表示） |
| `03_all_invalid.csv` | 取込0・エラー5 |
| `04_missing_required_column.csv` | 「読み込めませんでした」＋書式を見る |
| `05_empty.csv` | 「読み込めませんでした」（クラッシュしない） |
| `06_edge_cases.csv` | 1億/2000/2100の3件のみ取込・4件スキップ（MultiErrorは1枠に複数） |

## 手動のみのケース（Excel参照）
通知（背面/前面）、レビュー誘導ポップアップ、応援メニュー、共有、テーマ色グリッド、
アイコンの縁、ヘッダー配置、累計額レイアウト など。詳細と手順は `test_cases.xlsx`。

## 期待どおりでない場合
「エラー修正計画 → 修正 → 再テスト → ドキュメント更新」のサイクルで対応する。
