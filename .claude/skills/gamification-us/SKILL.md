# Skill: Gamification & Engagement UX Pattern

## 概要
このSkillは、学習アプリケーションにおけるユーザーの継続率（Retention）を最大化し、学習体験にゲームのような没入感と達成感（Gamification）をもたらすUI/UX実装ルールを定義します。

## 指導・実装原則

### 1. 継続メカニクス (Retention Mechanics)
- **ストリーク表示 (Daily Streak)**
  - ホーム画面や学習完了画面には、必ず「🔥 〇日連続学習中」のストリークUIを配置すること。
  - アイコンやテキストには、メラメラ揺れるようなアニメーション（Pulse/Breathing）を付与すること。
- **レベル & 経験値 (XP & Leveling)**
  - 問題解決・カード完了ごとにXPを獲得するアニメーション（+10 XPが浮き出て消える演出など）を入れること。
  - プログレスバーはただ動かすだけでなく、イージング（easeOutQuart等）を効かせて滑らかに増加させること。

### 2. コンボ & フィーバー演出 (Combo & Fever System)
- 正解が続いた場合（コンボ時）は、画面上に `COMBO x3` などのカウントアップテキストをバウンド（Spring physics）させながら表示すること。
- 5コンボ以上達成時は「FEVER MODE」として、画面枠の発光（Glow Effect）や獲得XPの倍率アップ演出を施すこと。

### 3. セレブレーション (Reward & Celebration)
- セッション完了時やレベルアップ時には、必ず画面全体に紙吹雪（Confetti）を降らせるコンポーネントを発火させること。
- ダイアログやポップアップが出現する際は、単にパッと出すのではなく、拡大しながら弾むアニメーション（Scale-up with Bounce/Spring）で表示すること。

### 4. 負の感情の軽減 (Loss Aversion Mitigation)
- 間違えた場合でも、暗い演出や嫌な効果音は避け、「どんまい！」「あと少し！」といったポップでポジティブな復習誘導UI（Card Flip/Slide）にすること。
