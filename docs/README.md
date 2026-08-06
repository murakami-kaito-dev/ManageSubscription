# docs/ — 運用ガイド（人間向け）

このフォルダは**人間が読む運用・作業ガイド**です。「アプリがどう動くか」という
**内部仕様は別の場所**（[`.claude/docs/`](../.claude/docs/)）にあります。

| 場所 | 目的 | 主な読者 |
|---|---|---|
| **`docs/`（ここ）** | セットアップ手順・テスト計画など、**作業のためのガイド** | 開発者（人間） |
| **`.claude/docs/`** | アプリの**仕様書**（アーキテクチャ/各画面/課金/通知 等）。ソースを読まずに把握する目的 | Claude Code / 開発者 |

## 収録物
- [monetization_setup.md](monetization_setup.md) — 課金（App Store Connect / RevenueCat）の本番化手順
- [testing/README.md](testing/README.md) — テスト計画（自動＋手動）
- [testing/test_cases.xlsx](testing/test_cases.xlsx) — テストケース一覧（Excel）
