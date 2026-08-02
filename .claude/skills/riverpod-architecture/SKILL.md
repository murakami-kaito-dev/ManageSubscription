# Skill: Riverpod + Feature-First Architecture

## 概要
このアプリ（サブスク管理）の状態管理・レイヤリングの統一ルール。flutter_riverpod を用いた、テスト可能で破綻しにくい構成を定義する。

## レイヤ構成（feature-first + 3層）
```
lib/
  core/        … theme / 共通widget / util（機能に依存しない）
  data/        … models(immutable) / database / repositories
  providers/   … Riverpod provider（アプリ横断の状態）
  features/    … 画面単位。screen + 画面固有widget
  services/    … 外部連携（ads / purchases / notifications / csv）
```
依存方向は **features → providers → data → core** の一方向のみ。逆流させない。

## Riverpod 原則
1. **Repository は `Provider`** で公開し、DB(`Database`)は `FutureProvider` で一度だけ open する。
2. 一覧など読み取り系は `AsyncNotifierProvider`（または `FutureProvider.family`）を使い、`AsyncValue` で loading/error を UI に伝える。書き込み後は `ref.invalidateSelf()` / 対象 provider を invalidate して再取得する。
3. 単純な設定値（通貨・並べ替え・プレミアム状態）は `Notifier`＋`shared_preferences` で永続化。
4. UI から Repository を直接呼ばない。必ず Notifier のメソッド経由。
5. `select` で必要なフィールドだけ購読し、無駄な rebuild を避ける。
6. 副作用（課金・広告・通知）は `services/` の抽象に閉じ込め、provider から呼ぶ。テスト時は差し替え可能にする。

## モデル
- `data/models` は immutable（`final` フィールド + `copyWith` + `fromMap`/`toMap`）。
- 金額は「最小通貨単位でなく double 円」で保持しつつ、表示は util の `CurrencyFormatter` に集約。

## プレミアム制限
- 制限判定は `PremiumLimits` に集約（登録数上限・CSV・並べ替え・画像・分析軸・期間閲覧）。
- UI では「上限に達したら CTA を出す」形にし、判定ロジックを画面に散らさない。

## 命名
- Provider は `xxxProvider`。Notifier クラスは `XxxNotifier`。
- 非同期一覧は `subscriptionsProvider`（`AsyncValue<List<Subscription>>`）のように複数形。
