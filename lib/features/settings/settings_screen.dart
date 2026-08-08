import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/monetization/iap.dart';
import '../../core/store_links.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/premium_crown.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../data/models/app_settings.dart';
import '../../providers/core_providers.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_providers.dart';
import '../premium/premium_screen.dart';
import '../csv/csv_import_help_screen.dart';
import '../csv/csv_import_screen.dart';
import 'feedback_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    if (!ref.read(premiumProvider)) {
      PremiumScreen.show(context, reason: 'CSVエクスポートはプレミアム機能です。');
      return;
    }
    final subs = ref.read(subscriptionsProvider).valueOrNull ?? const [];
    if (subs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('エクスポートするデータがありません')));
      return;
    }
    await ref.read(csvExportServiceProvider).exportSubscriptions(
          subs,
          ref.read(categoriesMapProvider),
          ref.read(paymentMethodsMapProvider),
        );
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    if (!ref.read(premiumProvider)) {
      PremiumScreen.show(context, reason: 'CSVインポートはプレミアム機能です。');
      return;
    }
    final service = ref.read(csvImportServiceProvider);
    String? text;
    try {
      text = await service.pickCsvText();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('ファイルを開けませんでした')));
      }
      return;
    }
    if (text == null) return; // cancelled
    final cats = ref.read(categoriesProvider).valueOrNull ?? const [];
    final methods = ref.read(paymentMethodsProvider).valueOrNull ?? const [];
    final result = service.parse(
      text,
      categoryNameToId: {for (final c in cats) c.name: c.id},
      methodNameToId: {for (final m in methods) m.name: m.id},
      startSortOrder: ref.read(subscriptionCountProvider),
    );
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CsvImportPreviewScreen(result: result),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);
    final entitlement = ref.watch(entitlementProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: '設定',
              // Close on the RIGHT — same position as the gear that opened it.
              trailing: SoftIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 40),
                children: [
                  _PremiumBanner(entitlement: entitlement),
                  const SectionHeader('設定'),
                  SoftCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _Row(
                          icon: Icons.notifications_rounded,
                          label: '支払い日前に通知でお知らせ',
                          trailing: Switch(
                            value: settings.notifyEnabled,
                            onChanged: (v) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setNotifyEnabled(v);
                              if (v) {
                                ref
                                    .read(notificationServiceProvider)
                                    .requestPermission();
                              }
                              final subs = ref
                                      .read(subscriptionsProvider)
                                      .valueOrNull ??
                                  const [];
                              ref
                                  .read(notificationServiceProvider)
                                  .rescheduleAll(subs, enabled: v);
                            },
                          ),
                        ),
                        const _Div(),
                        _Row(
                          icon: Icons.currency_yen_rounded,
                          label: 'メイン通貨',
                          trailing: Text(settings.mainCurrency.code,
                              style: AppType.body(14,
                                  color: AppColors.textSecondary)),
                          onTap: () => _pickCurrency(context, ref),
                        ),
                        const _Div(),
                        _Row(
                          icon: Icons.palette_rounded,
                          label: 'テーマカラーを選択',
                          trailing: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: settings.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          onTap: () => _pickAccent(context, ref),
                        ),
                        const _Div(),
                        _Row(
                          icon: Icons.description_rounded,
                          label: 'データをCSVエクスポート',
                          // Crown only for non-premium (already-premium users
                          // shouldn't see the upsell marker).
                          premium: !isPremium,
                          onTap: () => _exportCsv(context, ref),
                        ),
                        const _Div(),
                        _Row(
                          icon: Icons.file_upload_rounded,
                          label: 'CSVから読み込み',
                          premium: !isPremium,
                          onTap: () => _importCsv(context, ref),
                        ),
                        const _Div(),
                        _Row(
                          icon: Icons.help_outline_rounded,
                          label: 'CSVの書式・サンプル',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CsvImportHelpScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader('アプリ'),
                  SoftCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _Row(
                          icon: Icons.favorite_rounded,
                          label: 'このアプリを応援する',
                          onTap: () =>
                              ref.read(ratingServiceProvider).rate(),
                        ),
                        const _Div(),
                        _Row(
                          icon: Icons.share_rounded,
                          label: 'シェア',
                          onTap: () => Share.share(
                              'サブスク家計簿で毎月の固定費を見える化しよう！\n'
                              '${StoreLinks.shareUrl()}'),
                        ),
                        const _Div(),
                        _Row(
                          icon: Icons.mail_rounded,
                          label: 'ご意見・ご要望',
                          onTap: () => showFeedbackSheet(context),
                        ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.xxl),
                  Center(
                    child: Pressable(
                      // Hidden debug: long-press version to toggle premium.
                      onLongPress: () async {
                        await ref.read(premiumProvider.notifier).debugToggle();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ref.read(premiumProvider)
                                  ? 'デバッグ: プレミアム ON'
                                  : 'デバッグ: プレミアム OFF')));
                        }
                      },
                      child: Text('v1.0.0',
                          style:
                              AppType.body(12, color: AppColors.textMuted)),
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) async {
    final current = ref.read(settingsProvider).mainCurrency;
    final picked = await showModalBottomSheet<AppCurrency>(
      context: context,
      backgroundColor: AppColors.canvas,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(AppSpacing.lg),
            Text('メイン通貨', style: AppType.display(18)),
            const Gap(AppSpacing.sm),
            for (final c in AppCurrency.values)
              ListTile(
                title: Text('${c.symbol}  ${c.code}'),
                trailing: c == current
                    ? Icon(Icons.check_rounded, color: AppAccent.of(context).primary)
                    : null,
                onTap: () => Navigator.pop(context, c),
              ),
            const Gap(AppSpacing.lg),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setCurrency(picked);
    }
  }

  Future<void> _pickAccent(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.canvas,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('テーマカラー', style: AppType.display(18)),
              const Gap(AppSpacing.xl),
              // Fixed 3-column grid so every circle sits on the same vertical
              // and horizontal line regardless of label length.
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: 0.82,
                children: [
                  for (final a in ThemeAccent.options)
                    Pressable(
                      scale: 0.85,
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .setAccent(a.color.value);
                        Navigator.pop(context);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: a.color,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.soft(),
                            ),
                          ),
                          const Gap(6),
                          Text(a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.body(11)),
                        ],
                      ),
                    ),
                ],
              ),
              const Gap(AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.entitlement});
  final Entitlement entitlement;

  @override
  Widget build(BuildContext context) {
    // Paid → an info banner. Free → the upgrade promo (below).
    if (entitlement.isPremium) {
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppAccent.of(context).soft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: AppColors.gold, size: 28),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entitlement.kind.label}をご利用中',
                      style: AppType.display(17)),
                  Text('すべての機能をご利用いただけます',
                      style:
                          AppType.body(12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Pressable(
      onTap: () => PremiumScreen.show(context),
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.premiumGradient,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: AppShadows.accentGlow(AppAccent.of(context).primary, intensity: 1.2),
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 30)),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('プレミアムを無料でお試し',
                      style: AppType.display(19, color: AppColors.onPrimary)),
                  const Gap(2),
                  Text('一生分のお得をあなたに',
                      style: AppType.body(12.5,
                          color: AppColors.onPrimary.withOpacity(0.9))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onPrimary),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.premium = false,
  });
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppAccent.of(context).deep),
            const Gap(AppSpacing.md),
            Expanded(child: Text(label, style: AppType.body(15))),
            if (premium) ...[const PremiumCrown(size: 15), const Gap(AppSpacing.sm)],
            if (trailing != null) trailing!,
            if (trailing == null && !premium)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Divider(height: 1, color: AppColors.textMuted.withOpacity(0.15)),
      );
}
