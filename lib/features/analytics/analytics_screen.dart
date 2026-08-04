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
import '../home/subscription_form_screen.dart';
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

  /// Currently selected donut slice (-1 = none). Drives the center label and
  /// the highlighted legend row.
  int _selected = -1;

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
              onChanged: (s) => setState(() {
                _scope = s;
                _selected = -1;
              }),
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
                            setState(() {
                              _axis = a;
                              _selected = -1;
                            });
                          },
                        ),
                        const Gap(AppSpacing.lg),
                        DonutChart(
                          slices: result.slices,
                          total: result.total,
                          formatter: fmt,
                          selectedIndex: _selected,
                          onTapSlice: (i) => setState(
                              () => _selected = _selected == i ? -1 : i),
                          onLongPressSlice: (i) =>
                              _onLongPress(result.slices[i]),
                        ),
                        const Gap(AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: AppSpacing.xs, bottom: AppSpacing.sm),
                          child: Text(
                              _axis == AnalyticsAxis.subscription
                                  ? '項目をタップで選択、長押しで編集できます'
                                  : '項目をタップで選択、長押しで内訳を表示します',
                              style: AppType.body(11.5,
                                  color: AppColors.textMuted)),
                        ),
                        _Legend(
                          slices: result.slices,
                          fmt: fmt,
                          axis: _axis,
                          selectedIndex: _selected,
                          onTap: (i) => setState(
                              () => _selected = _selected == i ? -1 : i),
                          onLongPress: (slice) => _onLongPress(slice),
                        ),
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

  /// Long-press behaviour differs by axis: on サブスク別 it jumps straight to
  /// that subscription's editor (the old 1-item "breakdown" was pointless); on
  /// category / payment-method it still opens the multi-item breakdown.
  void _onLongPress(AnalyticsSlice slice) {
    if (_axis == AnalyticsAxis.subscription) {
      final subs = ref.read(subscriptionsProvider).valueOrNull ?? const [];
      final match = subs.where((s) => s.id == slice.groupKey);
      if (match.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SubscriptionFormScreen(existing: match.first),
        ));
      }
      return;
    }
    _openBreakdown(slice);
  }

  void _openBreakdown(AnalyticsSlice slice) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.canvas,
      isScrollControlled: true,
      builder: (_) => _BreakdownSheet(axis: _axis, slice: slice),
    );
  }
}

/// The list of subscriptions inside a tapped category/method slice. Tapping a
/// row opens that subscription's editor.
class _BreakdownSheet extends ConsumerWidget {
  const _BreakdownSheet({required this.axis, required this.slice});
  final AnalyticsAxis axis;
  final AnalyticsSlice slice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(
        analyticsMembersProvider(AnalyticsMemberQuery(axis, slice.groupKey)));
    final fmt = ref.watch(mainCurrencyFormatterProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: ListView(
          controller: controller,
          children: [
            const Gap(AppSpacing.md),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Gap(AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                      color: slice.color,
                      borderRadius: BorderRadius.circular(4)),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                    child: Text('${slice.label} の内訳',
                        style: AppType.display(19))),
                Text('${members.length}件',
                    style: AppType.body(13, color: AppColors.textSecondary)),
              ],
            ),
            const Gap(AppSpacing.md),
            for (final s in members)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SoftCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SubscriptionFormScreen(existing: s),
                    ));
                  },
                  child: Row(
                    children: [
                      SubscriptionAvatar(sub: s, size: 40),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style:
                                    AppType.body(15, weight: FontWeight.w700)),
                            Text('${CurrencyFormatter(s.currency).format(s.amount)} /${s.periodLabel}',
                                style: AppType.body(12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(fmt.format(s.monthlyAmountIn(
                          ref.watch(settingsProvider).mainCurrency)),
                          style: AppType.display(15)),
                      const Gap(AppSpacing.sm),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            const Gap(AppSpacing.xxl),
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

class _Legend extends ConsumerWidget {
  const _Legend({
    required this.slices,
    required this.fmt,
    required this.axis,
    required this.selectedIndex,
    required this.onTap,
    this.onLongPress,
  });
  final List<AnalyticsSlice> slices;
  final CurrencyFormatter fmt;
  final AnalyticsAxis axis;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final void Function(AnalyticsSlice)? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsById = {
      for (final s in ref.watch(subscriptionsProvider).valueOrNull ?? const [])
        s.id: s
    };
    return SoftCard(
      padding: EdgeInsets.zero,
      // Clip so the selected-row color wash respects the card's rounded corners.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Column(
        children: [
          for (var i = 0; i < slices.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Divider(
                    height: 1, color: AppColors.textMuted.withOpacity(0.15)),
              ),
            Pressable(
              onTap: () => onTap(i),
              onLongPress: onLongPress == null
                  ? null
                  : () => onLongPress!(slices[i]),
              scale: 0.99,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                // Highlight the selected row with a faint wash of the item's
                // own color.
                color: i == selectedIndex
                    ? slices[i].color.withOpacity(0.16)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: 14),
                child: Row(
                  children: [
                    if (axis == AnalyticsAxis.subscription &&
                        subsById[slices[i].groupKey] != null)
                      SubscriptionAvatar(
                          sub: subsById[slices[i].groupKey]!,
                          size: 30,
                          radius: 10)
                    else
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
                          style: AppType.body(15,
                              weight: i == selectedIndex
                                  ? FontWeight.w800
                                  : FontWeight.w600)),
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
            ),
          ],
        ],
        ),
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
