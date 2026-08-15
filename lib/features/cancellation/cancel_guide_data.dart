import 'package:flutter/material.dart';

/// 「解約方法」タブが表示する**静的なリンク集**（アプリ同梱・通信なし・収集なし）。
///
/// 方針: **手順は書き写さない**。公式の画面はすぐ変わるので、書き写した手順は
/// そのまま誤案内になる。各サービスが持つのは
/// 「公式の解約入口ページ（[CancelGuideEntry.url]）」＋「どこから解約するか（[CancelGuideEntry.route]）」
/// ＋「解約前の注意（[CancelGuideEntry.caution]）」だけ。
///
/// このアプリから解約手続きは**できない**（公式ページを外部ブラウザで開くだけ）。
/// 文言でもそう言い切ること。
///
/// URL は腐る前提。リリース前に一度は実際に開いて確認する。
enum CancelCategory {
  /// 最上段。日本のサブスクはアプリ内課金経由が多く、その場合の解約先は
  /// サービスのサイトではなく App Store / Google Play。
  platform('登録先（App Store / Google Play）', Icons.phone_iphone_rounded),
  video('動画', Icons.movie_rounded),
  music('音楽', Icons.music_note_rounded),
  work('仕事・AI・クラウド', Icons.cloud_rounded),
  game('ゲーム', Icons.sports_esports_rounded),
  reading('読書・雑誌・生活', Icons.menu_book_rounded),
  education('学び・教育', Icons.school_rounded),
  fitness('フィットネス・健康', Icons.fitness_center_rounded),
  thisApp('このアプリ（サブスク家計簿）', Icons.savings_rounded);

  const CancelCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

@immutable
class CancelGuideEntry {
  const CancelGuideEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.url,
    required this.route,
    this.caution,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final CancelCategory category;

  /// 公式の解約入口ページ。`url_launcher` で外部ブラウザに渡す。
  final String url;

  /// どこから解約するか（ブラウザ / アプリ / OS の設定）。
  final String route;

  /// 解約前に知っておくべきこと（日割りなし・解約金・課金経路の違いなど）。
  final String? caution;

  /// 検索用の別名（カナ・英語表記・略称）。
  /// 将来、登録済みサブスクのサービス名との文字列一致にも使える。
  final List<String> aliases;

  /// 検索クエリ（前後空白は呼び出し側で除去済み）にマッチするか。
  bool matches(String query) {
    final q = query.toLowerCase();
    if (name.toLowerCase().contains(q)) return true;
    for (final a in aliases) {
      if (a.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}

/// App Store のサブスクリプション管理ページ。iPhone では「設定 → 自分の名前 →
/// サブスクリプション」と同じ場所が開く。アプリ内課金で登録したものは全部ここ。
const String kAppStoreSubscriptionsUrl =
    'https://apps.apple.com/account/subscriptions';

/// Google Play の定期購入ページ。
const String kGooglePlaySubscriptionsUrl =
    'https://play.google.com/store/account/subscriptions';

/// 収録サービス。**網羅は狙わない**（80/20）。日本のユーザーが実際に契約している
/// 上位帯だけを載せ、増やすときも「本当に多い順」で足す。
const List<CancelGuideEntry> kCancelGuideEntries = [
  // ── 登録先（まずここを確認） ─────────────────────────────────────────────
  CancelGuideEntry(
    id: 'app_store',
    name: 'App Store で登録したサブスク',
    category: CancelCategory.platform,
    url: kAppStoreSubscriptionsUrl,
    route: 'iPhone / iPad の「設定」→ 一番上の自分の名前 → サブスクリプション からも同じ画面が開きます。',
    caution: 'アプリ内から登録したサブスクは、サービスのサイトではなくここから解約します。'
        '解約しても、支払い済みの期間が終わるまでは利用できます。',
    aliases: ['Apple', 'アップル', 'iPhone', 'iTunes', 'アプリ内課金'],
  ),
  CancelGuideEntry(
    id: 'google_play',
    name: 'Google Play で登録したサブスク',
    category: CancelCategory.platform,
    url: kGooglePlaySubscriptionsUrl,
    route: 'Play ストアアプリ → 右上のアカウントアイコン → お支払いと定期購入 → 定期購入 からも開けます。',
    caution: 'Android のアプリ内から登録したサブスクは、サービスのサイトではなくここから解約します。',
    aliases: ['Android', 'アンドロイド', 'プレイストア', 'アプリ内課金'],
  ),

  // ── 動画 ────────────────────────────────────────────────────────────────
  CancelGuideEntry(
    id: 'netflix',
    name: 'Netflix',
    category: CancelCategory.video,
    url: 'https://www.netflix.com/cancelplan',
    route: 'ブラウザでログイン →「メンバーシップのキャンセル」。',
    caution: '解約後も、請求期間の最終日までは視聴できます。',
    aliases: ['ネットフリックス'],
  ),
  CancelGuideEntry(
    id: 'amazon_prime',
    name: 'Amazon プライム / Prime Video',
    category: CancelCategory.video,
    url: 'https://www.amazon.co.jp/gp/primecentral',
    route: 'Amazon の「プライム会員情報」→ 会員資格を終了する。',
    caution: 'Prime Video だけをやめることはできません（プライム会員全体の解約になります）。',
    aliases: ['アマゾン', 'プライムビデオ', 'Prime'],
  ),
  CancelGuideEntry(
    id: 'disney_plus',
    name: 'Disney+（ディズニープラス）',
    category: CancelCategory.video,
    url: 'https://www.disneyplus.com/ja-jp/commerce/subscription',
    route: 'ブラウザでログイン → アカウント → サブスクリプション。',
    caution: 'ドコモ経由・App Store 経由など、登録した経路によって解約先が変わります。'
        '見つからないときは上の「登録先」も確認してください。',
    aliases: ['ディズニープラス', 'ディズニー'],
  ),
  CancelGuideEntry(
    id: 'unext',
    name: 'U-NEXT',
    category: CancelCategory.video,
    url: 'https://account.unext.jp/',
    route: 'ブラウザでログイン → アカウント設定 → 契約内容の確認・解約。',
    caution: 'アプリからは解約できません（ブラウザのみ）。残ったポイントは解約すると使えなくなります。',
    aliases: ['ユーネクスト', 'ユーネク'],
  ),
  CancelGuideEntry(
    id: 'dazn',
    name: 'DAZN',
    category: CancelCategory.video,
    url: 'https://www.dazn.com/ja-JP/account/subscription',
    route: 'ブラウザでログイン → マイ・アカウント → 退会する。',
    caution: '年間プランは途中解約に条件がある場合があります。',
    aliases: ['ダゾーン'],
  ),
  CancelGuideEntry(
    id: 'hulu',
    name: 'Hulu（日本）',
    category: CancelCategory.video,
    url: 'https://www.hulu.jp/account',
    route: 'ブラウザでログイン → アカウント → 解約する。',
    aliases: ['フールー'],
  ),
  CancelGuideEntry(
    id: 'abema',
    name: 'ABEMA プレミアム',
    category: CancelCategory.video,
    url: 'https://abema.tv/account',
    route: 'ブラウザまたはアプリでログイン → アカウント → プランの解約。',
    caution: '登録した経路（App Store / Google Play / ABEMA 公式）によって解約先が変わります。',
    aliases: ['アベマ'],
  ),
  CancelGuideEntry(
    id: 'danime',
    name: 'd アニメストア',
    category: CancelCategory.video,
    url: 'https://animestore.docomo.ne.jp/animestore/mp_viw_pc',
    route: 'd アカウントでログイン → 解約 / 解約状況の確認。',
    aliases: ['ダニメ', 'docomo', 'ドコモ'],
  ),
  CancelGuideEntry(
    id: 'lemino',
    name: 'Lemino（レミノ）',
    category: CancelCategory.video,
    url: 'https://lemino.docomo.ne.jp/',
    route: 'd アカウントでログイン → メニュー → 契約・解約 → Lemino プレミアムの解約。',
    caution: '旧 dTV から移行した契約もここから解約します。',
    aliases: ['レミノ', 'dTV', 'ディーティービー', 'docomo', 'ドコモ'],
  ),
  CancelGuideEntry(
    id: 'fod',
    name: 'FOD（フジテレビオンデマンド）',
    category: CancelCategory.video,
    url: 'https://fod.fujitv.co.jp/',
    route: 'ブラウザでログイン → マイメニュー → 月額コースの確認・解約。',
    caution: '登録した経路（Amazon / App Store / FOD 公式）によって解約先が変わります。',
    aliases: ['エフオーディー', 'フジテレビ'],
  ),
  CancelGuideEntry(
    id: 'telasa',
    name: 'TELASA（テラサ）',
    category: CancelCategory.video,
    url: 'https://www.telasa.jp/',
    route: 'au ID でログイン → マイページ → 登録情報の確認・解約。',
    aliases: ['テラサ', 'au', 'KDDI', 'ビデオパス'],
  ),
  CancelGuideEntry(
    id: 'wowow',
    name: 'WOWOW',
    category: CancelCategory.video,
    url: 'https://www.wowow.co.jp/support/cancel/',
    route: '公式の解約案内ページ → 加入者ページ（My WOWOW）から解約手続き。',
    caution: '解約は当月末など締め日の扱いがあり、Web だけで完結しない場合があります。'
        '案内ページの手順に従ってください。',
    aliases: ['ワウワウ'],
  ),
  CancelGuideEntry(
    id: 'dmm_tv',
    name: 'DMM TV / DMM プレミアム',
    category: CancelCategory.video,
    url: 'https://www.dmm.com/my/-/subscription/',
    route: 'DMM アカウントでログイン → 月額サービス（会員登録内容）→ DMM プレミアムの解約。',
    caution: 'App Store / Google Play のアプリ内課金で登録した場合は、そちらから解約します。'
        '「解約手続き中」でも有効期限までは視聴できます。',
    aliases: ['ディーエムエム', 'DMMプレミアム', 'DMMTV'],
  ),
  CancelGuideEntry(
    id: 'niconico_premium',
    name: 'ニコニコプレミアム',
    category: CancelCategory.video,
    url: 'https://premium.nicovideo.jp/',
    route: 'niconico にログイン → アカウント設定 → プレミアム会員 → 解約。',
    caution: 'スマホのアプリ内課金や、まとめて支払いなどの登録経路によって解約先が変わることがあります。',
    aliases: ['ニコニコ動画', 'niconico', 'ニコ動', 'ドワンゴ'],
  ),

  // ── 音楽 ────────────────────────────────────────────────────────────────
  CancelGuideEntry(
    id: 'spotify',
    name: 'Spotify',
    category: CancelCategory.music,
    url: 'https://www.spotify.com/jp/account/overview/',
    route: 'ブラウザでログイン → アカウント → プランの変更・解約。',
    caution: 'アプリからは解約できません（ブラウザのみ）。',
    aliases: ['スポティファイ'],
  ),
  CancelGuideEntry(
    id: 'apple_music',
    name: 'Apple Music',
    category: CancelCategory.music,
    url: kAppStoreSubscriptionsUrl,
    route: 'App Store のサブスクリプション画面から解約します（iPhone の「設定」からも同じ）。',
    aliases: ['アップルミュージック'],
  ),
  CancelGuideEntry(
    id: 'amazon_music',
    name: 'Amazon Music Unlimited',
    category: CancelCategory.music,
    url: 'https://www.amazon.co.jp/music/settings',
    route: 'Amazon の「Amazon Music の設定」→ 会員登録の更新とキャンセル。',
    aliases: ['アマゾンミュージック'],
  ),
  CancelGuideEntry(
    id: 'youtube_premium',
    name: 'YouTube Premium / YouTube Music',
    category: CancelCategory.music,
    url: 'https://www.youtube.com/paid_memberships',
    route: 'ブラウザでログイン → 有料メンバーシップ → 無効にする。',
    caution: 'iPhone アプリから登録した場合は、App Store のサブスクリプションから解約します。',
    aliases: ['ユーチューブ', 'YouTube'],
  ),
  CancelGuideEntry(
    id: 'line_music',
    name: 'LINE MUSIC',
    category: CancelCategory.music,
    url: 'https://music.line.me/',
    route: 'アプリまたはブラウザでログイン → マイページ → プランの確認・解約。',
    caution: 'アプリ内課金で登録した場合は、App Store / Google Play から解約します。',
    aliases: ['ラインミュージック', 'LINE', 'ライン'],
  ),

  // ── 仕事・AI・クラウド ───────────────────────────────────────────────────
  CancelGuideEntry(
    id: 'chatgpt',
    name: 'ChatGPT Plus',
    category: CancelCategory.work,
    url: 'https://chatgpt.com/',
    route: 'ブラウザでログイン → アカウント → Settings → Subscription → Cancel。',
    caution: 'iPhone アプリから登録した場合は、App Store のサブスクリプションから解約します。',
    aliases: ['チャットGPT', 'OpenAI', 'オープンAI'],
  ),
  CancelGuideEntry(
    id: 'claude',
    name: 'Claude Pro / Max',
    category: CancelCategory.work,
    url: 'https://claude.ai/settings/billing',
    route: 'ブラウザでログイン → 設定 → Billing（請求）→ プランをキャンセル。',
    caution: 'iPhone アプリから登録した場合は、App Store のサブスクリプションから解約します。',
    aliases: ['クロード', 'Anthropic', 'アンソロピック'],
  ),
  CancelGuideEntry(
    id: 'adobe_cc',
    name: 'Adobe Creative Cloud',
    category: CancelCategory.work,
    url: 'https://account.adobe.com/plans',
    route: 'Adobe アカウント → プランを管理 → プランの解約。',
    caution: '年間プランを途中で解約すると、解約金がかかる場合があります。',
    aliases: ['アドビ', 'Photoshop', 'Illustrator'],
  ),
  CancelGuideEntry(
    id: 'microsoft_365',
    name: 'Microsoft 365',
    category: CancelCategory.work,
    url: 'https://account.microsoft.com/services',
    route: 'Microsoft アカウント → サービスとサブスクリプション → 定期請求をオフ。',
    aliases: ['マイクロソフト', 'Office', 'オフィス'],
  ),
  CancelGuideEntry(
    id: 'google_one',
    name: 'Google One',
    category: CancelCategory.work,
    url: 'https://one.google.com/settings',
    route: 'Google One → 設定 → メンバーシップを解約。',
    caution: '容量が減ると、超過分の写真やファイルが扱えなくなることがあります。先にバックアップを。',
    aliases: ['グーグルワン', 'Google Drive', 'グーグルドライブ'],
  ),
  CancelGuideEntry(
    id: 'icloud',
    name: 'iCloud+',
    category: CancelCategory.work,
    url: kAppStoreSubscriptionsUrl,
    route: 'iPhone の「設定」→ 自分の名前 → サブスクリプション から解約します。',
    caution: '容量が減ると、超過分の写真やバックアップが保存できなくなります。先にバックアップを。',
    aliases: ['アイクラウド', 'Apple'],
  ),
  CancelGuideEntry(
    id: 'dropbox',
    name: 'Dropbox',
    category: CancelCategory.work,
    url: 'https://www.dropbox.com/account/plan',
    route: 'ブラウザでログイン → アカウント → プラン → プランのダウングレード。',
    caution: '無料プランの容量を超えている場合、超過分のファイルが同期できなくなります。',
    aliases: ['ドロップボックス'],
  ),
  CancelGuideEntry(
    id: 'canva',
    name: 'Canva Pro',
    category: CancelCategory.work,
    url: 'https://www.canva.com/settings/billing-and-plans/',
    route: 'ブラウザでログイン → 設定 → 請求とプラン → プランをキャンセル。',
    caution: 'Pro 限定の素材を使ったデザインは、解約後に編集・書き出しができなくなります。',
    aliases: ['キャンバ'],
  ),
  CancelGuideEntry(
    id: 'notion',
    name: 'Notion',
    category: CancelCategory.work,
    url: 'https://www.notion.so/',
    route: 'ブラウザでログイン → 設定 → 請求（Billing）→ プランのダウングレード。',
    caution: 'ワークスペースごとの契約です。複数のワークスペースを持っている場合は、'
        '課金されているワークスペースを選んでから解約します。',
    aliases: ['ノーション'],
  ),
  CancelGuideEntry(
    id: 'github_copilot',
    name: 'GitHub Copilot',
    category: CancelCategory.work,
    url: 'https://github.com/settings/billing/summary',
    route: 'ブラウザでログイン → Settings → Billing → Copilot の購読をキャンセル。',
    aliases: ['ギットハブ', 'コパイロット', 'Copilot'],
  ),

  // ── ゲーム ──────────────────────────────────────────────────────────────
  CancelGuideEntry(
    id: 'nintendo_switch_online',
    name: 'Nintendo Switch Online',
    category: CancelCategory.game,
    url: 'https://ec.nintendo.com/my/membership',
    route: 'ニンテンドーアカウントでログイン → 加入者向けメニュー → 自動更新の解除。',
    caution: '「解約」ではなく自動更新をオフにする方式です。'
        '期間が終わるまでは遊べます。ファミリープランは代表者のアカウントで操作します。',
    aliases: ['ニンテンドー', 'スイッチオンライン', 'Switch', 'ニンテンドースイッチ'],
  ),
  CancelGuideEntry(
    id: 'playstation_plus',
    name: 'PlayStation Plus',
    category: CancelCategory.game,
    url: 'https://id.sonyentertainmentnetwork.com/id/management/',
    route: 'PlayStation アカウントでログイン → 定期購入 → 自動更新をオフ。'
        'PS5/PS4 本体の「設定 → アカウント管理」からも同じ操作ができます。',
    caution: '自動更新をオフにしても、残っている期間は利用できます。'
        'フリープレイで入手したゲームは、解約すると遊べなくなります。',
    aliases: ['プレステ', 'プレイステーション', 'PS Plus', 'PS5', 'PS4', 'ソニー'],
  ),
  CancelGuideEntry(
    id: 'xbox_game_pass',
    name: 'Xbox Game Pass',
    category: CancelCategory.game,
    url: 'https://account.microsoft.com/services',
    route: 'Microsoft アカウント → サービスとサブスクリプション → 管理 → 定期請求をオフ。',
    aliases: ['エックスボックス', 'ゲームパス', 'Microsoft', 'マイクロソフト'],
  ),

  // ── 読書・雑誌・生活 ────────────────────────────────────────────────────
  CancelGuideEntry(
    id: 'kindle_unlimited',
    name: 'Kindle Unlimited',
    category: CancelCategory.reading,
    url: 'https://www.amazon.co.jp/kindle-dbs/hz/subscribe/ku/manage',
    route: 'Amazon の「Kindle Unlimited 会員登録を管理」→ 会員登録をキャンセル。',
    caution: '解約すると、読み放題で借りている本は読めなくなります。',
    aliases: ['キンドル', 'アマゾン'],
  ),
  CancelGuideEntry(
    id: 'dmagazine',
    name: 'd マガジン',
    category: CancelCategory.reading,
    url: 'https://dmagazine.docomo.ne.jp/',
    route: 'd アカウントでログイン → 設定 → 解約。',
    aliases: ['ディーマガジン', 'docomo', 'ドコモ'],
  ),
  CancelGuideEntry(
    id: 'rakuten_magazine',
    name: '楽天マガジン',
    category: CancelCategory.reading,
    url: 'https://magazine.rakuten.co.jp/',
    route: '楽天会員でログイン → マイページ → 契約内容の確認・解約。',
    aliases: ['らくてん', 'Rakuten'],
  ),
  CancelGuideEntry(
    id: 'audible',
    name: 'Audible（オーディブル）',
    category: CancelCategory.reading,
    url: 'https://www.audible.co.jp/account/overview',
    route: 'Amazon アカウントでログイン → アカウントサービス → 退会手続きへ。',
    caution: '無料体験中の解約は、終了日の前日までに。退会すると、'
        '会員特典で聴いていた作品は聴けなくなります（購入したタイトルは残ります）。',
    aliases: ['オーディブル', 'アマゾン', 'Amazon', '耳学', 'オーディオブック'],
  ),
  CancelGuideEntry(
    id: 'nikkei',
    name: '日経電子版',
    category: CancelCategory.reading,
    url: 'https://www.nikkei.com/my/',
    route: '日経 ID でログイン → マイページ → 登録内容の変更・解約。',
    caution: '解約しても、その月の締め日までは読めます。',
    aliases: ['にっけい', '日本経済新聞', '新聞'],
  ),
  CancelGuideEntry(
    id: 'uber_one',
    name: 'Uber One',
    category: CancelCategory.reading,
    url: 'https://www.ubereats.com/jp',
    route: 'Uber Eats アプリまたはブラウザ → アカウント → Uber One → メンバーシップを終了。',
    caution: 'アプリ内課金で登録した場合は、App Store / Google Play から解約します。',
    aliases: ['ウーバー', 'ウーバーイーツ', 'Uber Eats', '出前'],
  ),
  CancelGuideEntry(
    id: 'lyp_premium',
    name: 'LYP プレミアム（旧 Yahoo! プレミアム）',
    category: CancelCategory.reading,
    url: 'https://premium.yahoo.co.jp/',
    route: 'Yahoo! JAPAN ID でログイン →「LYP プレミアム会員ページ」→ 解約手続き。',
    caution: 'LINE / ソフトバンク・ワイモバイルまとめて支払い / App Store など、'
        '登録した経路によって解約先が変わります。LINE アプリからは解約できない場合があります。',
    aliases: ['エルワイピー', 'Yahoo', 'ヤフー', 'ヤフープレミアム', 'PayPay', 'LINE'],
  ),
  CancelGuideEntry(
    id: 'x_premium',
    name: 'X Premium（旧 Twitter Blue）',
    category: CancelCategory.reading,
    url: 'https://x.com/i/premium',
    route: 'ブラウザで X にログイン → 設定 → プレミアム → サブスクリプションの管理 → 解約。',
    caution: 'iPhone / Android のアプリ内課金で登録した場合は、App Store / Google Play から解約します。',
    aliases: ['エックス', 'Twitter', 'ツイッター', 'Twitter Blue', 'ツイッターブルー', 'Grok'],
  ),

  // ── 学び・教育 ──────────────────────────────────────────────────────────
  CancelGuideEntry(
    id: 'studysapuri',
    name: 'スタディサプリ',
    category: CancelCategory.education,
    url: 'https://studysapuri.jp/info/guide/cancellation/',
    route: 'サポート Web にログイン → 退会 / 利用停止の手続き。',
    caution: '「利用停止」と「退会」は別の手続きです。講座（小中高・大学受験・ENGLISH）や'
        '登録経路（App Store など）によって手続きが異なります。',
    aliases: ['スタサプ', 'studysapuri', 'リクルート', '受験'],
  ),
  CancelGuideEntry(
    id: 'duolingo',
    name: 'Duolingo（Super Duolingo）',
    category: CancelCategory.education,
    url: 'https://www.duolingo.com/help/cancel-my-super-duolingo-subscription',
    route: 'ブラウザでログイン → 設定 → サブスクリプション（Super）→ 解約。',
    caution: 'iPhone / Android のアプリ内課金で登録した場合は、App Store / Google Play から解約します。',
    aliases: ['デュオリンゴ', 'ドゥオリンゴ', 'Super Duolingo', '語学', '英語'],
  ),

  // ── フィットネス・健康 ──────────────────────────────────────────────────
  CancelGuideEntry(
    id: 'chocozap',
    name: 'chocoZAP（チョコザップ）',
    category: CancelCategory.fitness,
    url: 'https://faq.chocozap.jp/chocozap_faq/qa/cancel',
    route: 'chocoZAP アプリ → メニュー → 退会の手続き（マイページ → 退会の手続き からも可）。',
    caution: '最短で解約できるのは入会月の翌月末です。月額分は支払った月の末日まで使えます。'
        '料金の未納があるとアプリから退会できません。',
    aliases: ['チョコザップ', 'ちょこざっぷ', 'RIZAP', 'ライザップ', 'ジム'],
  ),

  // ── このアプリ（隠さず載せる） ───────────────────────────────────────────
  CancelGuideEntry(
    id: 'submana_premium',
    name: 'サブスク家計簿 プレミアム（月額 / 年額）',
    category: CancelCategory.thisApp,
    url: kAppStoreSubscriptionsUrl,
    route: 'iPhone の「設定」→ 自分の名前 → サブスクリプション →「サブスク家計簿」→ サブスクリプションをキャンセル。',
    caution: '買い切り（永久）プランは一度きりの購入なので、解約の必要はありません。',
    aliases: ['サブスク家計簿', 'submana', 'プレミアム'],
  ),
];

/// カテゴリー順・定義順に並んだセクション。
List<({CancelCategory category, List<CancelGuideEntry> entries})>
    cancelGuideSections() => [
          for (final c in CancelCategory.values)
            (
              category: c,
              entries: [
                for (final e in kCancelGuideEntries)
                  if (e.category == c) e
              ],
            ),
        ];

/// サービス名・別名の部分一致で絞り込む。空クエリなら全件。
List<CancelGuideEntry> searchCancelGuide(String query) {
  final q = query.trim();
  if (q.isEmpty) return kCancelGuideEntries;
  return [
    for (final e in kCancelGuideEntries)
      if (e.matches(q)) e
  ];
}
