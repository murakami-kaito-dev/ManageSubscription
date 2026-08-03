import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/premium_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_header.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/subscription.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_providers.dart';
import '../premium/premium_screen.dart';
import '../settings/settings_screen.dart';
import 'subscription_form_screen.dart';
import 'subscription_settings_sheet.dart';
import 'widgets/subscription_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openForm(BuildContext context, WidgetRef ref, {Subscription? existing}) {
    if (existing == null) {
      final isPremium = ref.read(premiumProvider);
      final count = ref.read(subscriptionCountProvider);
      if (!PremiumLimits.canAddSubscription(isPremium, count)) {
        PremiumScreen.show(
          context,
          reason: '無料版で登録できるのは${PremiumLimits.maxSubscriptions}件までです。'
              'プレミアムなら無制限に登録できます。',
        );
        return;
      }
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SubscriptionFormScreen(existing: existing),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubs = ref.watch(subscriptionsProvider);
    final visible = ref.watch(visibleSubscriptionsProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      floatingActionButton: _AddFab(onTap: () => _openForm(context, ref)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: 'サブスクリプション',
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              trailing: SoftIconButton(
                icon: Icons.more_horiz_rounded,
                onTap: () => showSubscriptionSettingsSheet(context),
              ),
            ),
            Expanded(
              child: asyncSubs.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('読み込みに失敗しました\n$e')),
                data: (all) {
                  final active = all.where((s) => !s.isPaused).toList();
                  if (all.isEmpty) {
                    return SoftEmptyState(
                      icon: Icons.subscriptions_rounded,
                      title: 'まだ登録がありません',
                      message: '毎月の支払いを追加して、\nサブスクを見える化しましょう。',
                      action: SoftButton(
                        label: '最初のサブスクを追加',
                        icon: Icons.add_rounded,
                        expand: false,
                        onPressed: () => _openForm(context, ref),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 120),
                    children: [
                      _SummaryCard(active: active),
                      const Gap(AppSpacing.lg),
                      _ListBody(
                        visible: visible,
                        manualSort: settings.sortMode == SortMode.manual,
                        onTapTile: (s) => _openForm(context, ref, existing: s),
                        onReorder: (list) =>
                            ref.read(subscriptionsProvider.notifier).reorder(list),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.active});
  final List<Subscription> active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final fmt = ref.watch(mainCurrencyFormatterProvider);
    final total = active.fold<double>(
        0, (sum, s) => sum + s.monthlyAmountIn(settings.mainCurrency));

    Subscription? next;
    for (final s in active) {
      if (next == null ||
          s.daysUntilNextPayment < next.daysUntilNextPayment) {
        next = s;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppAccent.of(context).primary, AppAccent.of(context).deep],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: AppShadows.accentGlow(AppAccent.of(context).primary, intensity: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今月の合計',
              style: AppType.body(13,
                  weight: FontWeight.w600,
                  color: AppColors.onPrimary.withOpacity(0.85))),
          const Gap(AppSpacing.xs),
          AnimatedCounter(
            value: total,
            formatter: (v) => fmt.format(v),
            style: AppType.display(34, color: AppColors.onPrimary),
          ),
          const Gap(AppSpacing.md),
          Row(
            children: [
              _Chip(
                icon: Icons.layers_rounded,
                label: '${active.length}件が利用中',
              ),
              const Gap(AppSpacing.sm),
              if (next != null)
                _Chip(
                  icon: Icons.event_rounded,
                  label: next.daysUntilNextPayment <= 0
                      ? '本日 ${next.name}'
                      : '次は${next.daysUntilNextPayment}日後',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onPrimary),
          const Gap(6),
          Text(label,
              style: AppType.body(12,
                  weight: FontWeight.w600, color: AppColors.onPrimary)),
        ],
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.visible,
    required this.manualSort,
    required this.onTapTile,
    required this.onReorder,
  });

  final List<Subscription> visible;
  final bool manualSort;
  final void Function(Subscription) onTapTile;
  final void Function(List<Subscription>) onReorder;

  @override
  Widget build(BuildContext context) {
    if (manualSort) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: true,
        itemCount: visible.length,
        onReorder: (oldIndex, newIndex) {
          final list = [...visible];
          if (newIndex > oldIndex) newIndex--;
          list.insert(newIndex, list.removeAt(oldIndex));
          onReorder(list);
        },
        // While dragging, lift ONLY the tile (not the trailing gap) so the
        // empty margin doesn't travel with the item.
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent,
          child: SubscriptionTile(
            sub: visible[index],
            onTap: () {},
          ),
        ),
        itemBuilder: (context, i) => Padding(
          key: ValueKey(visible[i].id),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: SubscriptionTile(
            sub: visible[i],
            onTap: () => onTapTile(visible[i]),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final s in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SubscriptionTile(sub: s, onTap: () => onTapTile(s)),
          ),
      ],
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppAccent.of(context).primary, AppAccent.of(context).deep],
          ),
          shape: BoxShape.circle,
          boxShadow: AppShadows.accentGlow(AppAccent.of(context).primary, intensity: 1.4),
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 30),
      ),
    );
  }
}
