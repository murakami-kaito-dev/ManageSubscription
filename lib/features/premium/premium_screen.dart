import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/legal.dart';
import '../../core/monetization/iap.dart';
import '../../core/premium_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/soft_button.dart';
import '../../providers/core_providers.dart';
import '../../providers/premium_provider.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key, this.reason});

  final String? reason;

  static Future<void> show(BuildContext context, {String? reason}) {
    return Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PremiumScreen(reason: reason),
    ));
  }

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  bool _busy = false;
  PlanKind _selected = PlanKind.yearly; // best value pre-selected
  Map<PlanKind, String> _prices = const {
    PlanKind.lifetime: Iap.priceLifetime,
    PlanKind.monthly: Iap.priceMonthly,
    PlanKind.yearly: Iap.priceYearly,
  };

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    final p = await ref.read(purchaseServiceProvider).loadPrices();
    if (mounted) setState(() => _prices = p);
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _purchase() async {
    setState(() => _busy = true);
    final ok = await ref.read(premiumProvider.notifier).purchase(_selected);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _confetti.play();
      await _celebrate();
      if (mounted) Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('購入を完了できませんでした。もう一度お試しください。')),
      );
    }
  }

  Future<void> _celebrate() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CelebrationDialog(),
    );
  }

  Future<void> _restore() async {
    final ok = await ref.read(premiumProvider.notifier).restore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'プレミアムを復元しました' : '復元できる購入がありませんでした')),
    );
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ent = ref.watch(entitlementProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Align(
                  // Close on the RIGHT, matching the settings screen's ✗.
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SoftIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                    children: [
                      const _Hero(),
                      if (widget.reason != null) ...[
                        const Gap(AppSpacing.lg),
                        _ReasonBanner(text: widget.reason!),
                      ],
                      const Gap(AppSpacing.lg),
                      _TrialBanner(entitlement: ent),
                      const Gap(AppSpacing.lg),
                      _PlanCard(
                        title: '年額プラン',
                        price: '${_prices[PlanKind.yearly]} / 年',
                        note: '2週間の無料体験つき・一番お得',
                        badge: 'おすすめ',
                        selected: _selected == PlanKind.yearly,
                        onTap: () =>
                            setState(() => _selected = PlanKind.yearly),
                      ),
                      const Gap(AppSpacing.sm),
                      _PlanCard(
                        title: '月額プラン',
                        price: '${_prices[PlanKind.monthly]} / 月',
                        note: '2週間の無料体験つき・いつでも解約可',
                        selected: _selected == PlanKind.monthly,
                        onTap: () =>
                            setState(() => _selected = PlanKind.monthly),
                      ),
                      const Gap(AppSpacing.sm),
                      _PlanCard(
                        title: '買い切り',
                        price: _prices[PlanKind.lifetime] ?? '',
                        note: '一度の購入でずっと使える',
                        selected: _selected == PlanKind.lifetime,
                        onTap: () =>
                            setState(() => _selected = PlanKind.lifetime),
                      ),
                      const Gap(AppSpacing.xl),
                      Text('プレミアムでできること',
                          textAlign: TextAlign.center,
                          style: AppType.display(18)),
                      const Gap(AppSpacing.lg),
                      const _ComparisonTable(),
                    ],
                  ),
                ),
                _PurchaseBar(
                  busy: _busy,
                  selected: _selected,
                  prices: _prices,
                  onPurchase: _purchase,
                  onRestore: _restore,
                  onStayFree: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              gravity: 0.25,
              colors: AppColors.chartPalette,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  const _TrialBanner({required this.entitlement});
  final Entitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final accent = AppAccent.of(context);
    final (IconData icon, String title, String body) =
        switch (entitlement.kind) {
      PlanKind.free => (
          Icons.lock_open_rounded,
          '無料プランで利用中',
          '月額・年額プランは2週間無料でお試しできます。',
        ),
      _ => (
          Icons.workspace_premium_rounded,
          '${entitlement.kind.label}をご利用中',
          'いつもありがとうございます。',
        ),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent.deep, size: 22),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.display(15)),
                const Gap(2),
                Text(body,
                    style: AppType.body(12.5,
                        color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.note,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final String title;
  final String price;
  final String note;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final accent = AppAccent.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? accent.soft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: selected ? accent.primary : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? null : AppShadows.soft(),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? accent.primary : AppColors.textMuted,
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppType.display(16)),
                      if (badge != null) ...[
                        const Gap(AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(badge!,
                              style: AppType.body(10,
                                  weight: FontWeight.w800,
                                  color: AppColors.onPrimary)),
                        ),
                      ],
                    ],
                  ),
                  const Gap(2),
                  Text(note,
                      style: AppType.body(11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(price, style: AppType.display(16)),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(AppSpacing.sm),
        Text('サブスク家計簿 プレミアム',
            textAlign: TextAlign.center, style: AppType.display(25)),
        const Gap(AppSpacing.lg),
        // The real app icon (same image the launcher uses).
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: AppShadows.accentGlow(AppAccent.of(context).primary,
                intensity: 1.4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
        ),
      ],
    );
  }
}

class _ReasonBanner extends StatelessWidget {
  const _ReasonBanner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.coralSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.coral, size: 20),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: AppType.body(13,
                    color: AppColors.textPrimary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  // (feature, free, premium)
  static const _rows = [
    ('サブスクの登録数', '${PremiumLimits.maxSubscriptions}件', '100件'),
    ('カテゴリーの登録数', '${PremiumLimits.maxCategories}件', '無制限'),
    ('支払い方法の登録数', '${PremiumLimits.maxPaymentMethods}件', '無制限'),
    ('支払い前の通知ルール数', '無制限', '無制限'),
    ('アイコン画像の登録', '×', '✓'),
    ('CSVエクスポート', '×', '✓'),
    ('CSVインポート', '×', '✓'),
    ('分析：カテゴリー別／支払い方法別', '✓', '✓'),
    ('カレンダー／履歴の閲覧範囲', '当月', '全期間'),
    ('サブスク別の分析・ホーム・合計', '✓', '✓'),
    ('並べ替え（自動ソート）', '✓', '✓'),
    ('テーマカラー変更', '✓', '✓'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: AppShadows.soft(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                    child: Text('機能',
                        style: AppType.body(13,
                            weight: FontWeight.w700,
                            color: AppColors.textSecondary))),
                SizedBox(
                    width: 54,
                    child: Text('無料',
                        textAlign: TextAlign.center,
                        style: AppType.body(13,
                            weight: FontWeight.w700,
                            color: AppColors.textSecondary))),
                Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppAccent.of(context).primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('プレミアム',
                      textAlign: TextAlign.center,
                      style: AppType.body(12,
                          weight: FontWeight.w700, color: AppColors.onPrimary)),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _rows.length; i++)
            Container(
              color: i.isEven ? AppColors.canvas.withOpacity(0.5) : null,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                      child: Text(_rows[i].$1, style: AppType.body(13))),
                  SizedBox(
                      width: 56, child: _cell(context, _rows[i].$2, false)),
                  SizedBox(
                      width: 84, child: _cell(context, _rows[i].$3, true)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// A single value cell: ✓/× render as icons, everything else as text.
  Widget _cell(BuildContext context, String v, bool premium) {
    final accent = AppAccent.of(context);
    if (v == '✓') {
      return Center(
          child: Icon(Icons.check_circle_rounded,
              color: premium ? accent.primary : AppColors.textSecondary,
              size: 20));
    }
    if (v == '×') {
      return const Center(
          child: Icon(Icons.remove_rounded, color: AppColors.textMuted, size: 18));
    }
    return Text(v,
        textAlign: TextAlign.center,
        style: AppType.body(12.5,
            weight: FontWeight.w700,
            color: premium ? accent.deep : AppColors.textMuted));
  }
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({
    required this.busy,
    required this.selected,
    required this.prices,
    required this.onPurchase,
    required this.onRestore,
    required this.onStayFree,
  });
  final bool busy;
  final PlanKind selected;
  final Map<PlanKind, String> prices;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onStayFree;

  String get _cta => switch (selected) {
        PlanKind.lifetime => '${prices[PlanKind.lifetime]} で購入する',
        PlanKind.monthly => '2週間無料で始める（その後 ${prices[PlanKind.monthly]}/月）',
        PlanKind.yearly => '2週間無料で始める（その後 ${prices[PlanKind.yearly]}/年）',
        _ => '続ける',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl,
          AppSpacing.md + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet)),
        boxShadow: AppShadows.raised(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoftButton(
            label: busy ? '処理中…' : _cta,
            icon: busy ? null : Icons.workspace_premium_rounded,
            onPressed: busy ? null : onPurchase,
          ),
          const Gap(AppSpacing.xs),
          Pressable(
            onTap: onStayFree,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('無料プランのまま使う',
                  style: AppType.body(13,
                      weight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _link('購入を復元', onRestore),
              _link('利用規約', () => _launch(Legal.terms)),
              _link('プライバシーポリシー', () => _launch(Legal.privacyPolicy)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {/* best-effort */}
  }

  Widget _link(String label, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(label,
              style: AppType.body(12, color: AppColors.textMuted)),
        ),
      );
}

class _CelebrationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.7, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 60, color: AppColors.gold),
              const Gap(AppSpacing.md),
              Text('プレミアム開始！', style: AppType.display(22)),
              const Gap(AppSpacing.sm),
              Text('すべての機能が使えるようになりました。',
                  textAlign: TextAlign.center,
                  style: AppType.body(14, color: AppColors.textSecondary)),
              const Gap(AppSpacing.xl),
              SoftButton(
                label: 'はじめる',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
