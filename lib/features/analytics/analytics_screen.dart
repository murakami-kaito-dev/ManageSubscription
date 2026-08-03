import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/premium_crown.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../core/widgets/subscription_avatar.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_providers.dart';
import '../premium/premium_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/donut_chart.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsScope _scope = AnalyticsScope.month;
  AnalyticsAxis _axis = AnalyticsAxis.subscription;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    final fmt = ref.watch(mainCurrencyFormatterProvider);
    final result =
        ref.watch(analyticsProvider(AnalyticsQuery(_scope, _axis)));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: '分析',
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const SettingsScreen()),
              ),
            ),
            _ScopeTabs(
              scope: _scope,
              onChanged: (s) => setState(() => _scope = s),
            ),
            Expanded(
              child: result.slices.isEmpty
                  ? const SoftEmptyState(
                      icon: Icons.pie_chart_rounded,
                      title: 'データがありません',
                      message: '利用中のサブスクを追加すると、\nここに支出の内訳が表示されます。',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 40),
                      children: [
                        _AxisSelector(
                          axis: _axis,
                          isPremium: isPremium,
                          onChanged: (a) {
                            if (a.isPremium && !isPremium) {
                              PremiumScreen.show(context,
                                  reason:
                                      'カテゴリー別・支払い方法別の分析はプレミアム機能です。');
                              return;
                            }
                            setState(() => _axis = a);
                          },
                        ),
                        const Gap(AppSpacing.lg),
                        DonutChart(
                          slices: result.slices,
                          total: result.total,
                          formatter: fmt,
                        ),
                        const Gap(AppSpacing.lg),
                        _Legend(slices: result.slices, fmt: fmt),
                        if (_axis == AnalyticsAxis.subscription) ...[
                          const SectionHeader('コスパチェッカー'),
                          _CospaList(scope: _scope),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.scope, required this.onChanged});
  final AnalyticsScope scope;
  final ValueChanged<AnalyticsScope> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, AnalyticsScope s) {
      final sel = scope == s;
      return Expanded(
        child: Pressable(
          onTap: () => onChanged(s),
          scale: 0.97,
          child: Column(
            children: [
              Text(label,
                  style: AppType.body(16,
                      weight: sel ? FontWeight.w800 : FontWeight.w500,
                      color: sel ? AppColors.textPrimary : AppColors.textMuted)),
              const Gap(AppSpacing.sm),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 3,
                width: sel ? 56 : 0,
                decoration: BoxDecoration(
                  color: AppAccent.of(context).primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, 0),
      child: Row(children: [
        tab('月間', AnalyticsScope.month),
        tab('年間', AnalyticsScope.year),
      ]),
    );
  }
}

class _AxisSelector extends StatelessWidget {
  const _AxisSelector(
      {required this.axis, required this.isPremium, required this.onChanged});
  final AnalyticsAxis axis;
  final bool isPremium;
  final ValueChanged<AnalyticsAxis> onChanged;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          for (final a in AnalyticsAxis.values)
            Expanded(
              child: Pressable(
                scale: 0.96,
                onTap: () => onChanged(a),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: axis == a ? AppAccent.of(context).primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.body(12.5,
                              weight: FontWeight.w700,
                              color: axis == a
                                  ? AppColors.onPrimary
                                  : AppColors.textSecondary),
                        ),
                      ),
                      if (a.isPremium && !isPremium) ...[
                        const Gap(3),
                        const PremiumCrown(size: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.slices, required this.fmt});
  final List<AnalyticsSlice> slices;
  final CurrencyFormatter fmt;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < slices.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Divider(
                    height: 1, color: AppColors.textMuted.withOpacity(0.15)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: slices[i].color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Text(slices[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body(15, weight: FontWeight.w600)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmt.format(slices[i].amount),
                          style: AppType.display(16)),
                      if (slices[i].nativeLabel != null)
                        Text(slices[i].nativeLabel!,
                            style: AppType.body(11,
                                color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Original feature surfaced in analytics:每 subscription's cost-per-use.
class _CospaList extends ConsumerWidget {
  const _CospaList({required this.scope});
  final AnalyticsScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = (ref.watch(subscriptionsProvider).valueOrNull ?? const [])
        .where((s) => !s.isPaused && s.costPerUse != null)
        .toList()
      ..sort((a, b) => a.costPerUse!.compareTo(b.costPerUse!));

    if (subs.isEmpty) {
      return SoftCard(
        child: Text('サブスクに「月の利用回数」を入力すると、\n1回あたりの単価がここに表示されます。',
            style: AppType.body(13, color: AppColors.textSecondary, height: 1.5)),
      );
    }

    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < subs.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Divider(
                    height: 1, color: AppColors.textMuted.withOpacity(0.15)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 14),
              child: Row(
                children: [
                  SubscriptionAvatar(sub: subs[i], size: 38, radius: 12),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subs[i].name,
                            style: AppType.body(15, weight: FontWeight.w700)),
                        Text('月 ${subs[i].usageCount.toStringAsFixed(0)}${subs[i].usageUnit}利用',
                            style: AppType.body(11.5,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: CurrencyFormatter(subs[i].currency)
                            .format(subs[i].costPerUse!),
                        style: AppType.display(17, color: AppAccent.of(context).deep),
                      ),
                      TextSpan(
                        text: ' /${subs[i].usageUnit}',
                        style: AppType.body(11, color: AppColors.textMuted),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
