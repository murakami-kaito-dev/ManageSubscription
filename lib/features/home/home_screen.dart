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
import '../subscription/subscription_form_screen.dart';
import 'home_selection_provider.dart';
import 'subscription_settings_sheet.dart';
import 'widgets/subscription_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openForm(BuildContext context, WidgetRef ref, {Subscription? existing}) {
    if (existing == null) {
      final count = ref.read(subscriptionCountProvider);
      // Silent hard cap (100 for everyone): only warn on the attempt to exceed.
      if (!PremiumLimits.underHardMax(count)) {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('これ以上は登録できません'),
            content: const Text(
                '登録できるサブスクは${PremiumLimits.hardMaxSubscriptions}件までです。'
                '不要なものを削除してから追加してください。'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK')),
            ],
          ),
        );
        return;
      }
      final isPremium = ref.read(premiumProvider);
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
    final selection = ref.watch(homeSelectionProvider);
    final selectionCtrl = ref.read(homeSelectionProvider.notifier);

    final allVisibleSelected = visible.isNotEmpty &&
        visible.every((s) => selection.ids.contains(s.id));

    return Scaffold(
      floatingActionButton:
          selection.active ? null : _AddFab(onTap: () => _openForm(context, ref)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (selection.active)
              SoftHeader(
                title: '${selection.count}件を選択',
                leading: SoftIconButton(
                  icon: Icons.close_rounded,
                  onTap: selectionCtrl.exit,
                ),
                trailing: _TextAction(
                  label: allVisibleSelected ? '全解除' : '全選択',
                  onTap: () => allVisibleSelected
                      ? selectionCtrl.clear()
                      : selectionCtrl.selectAll(visible.map((s) => s.id)),
                ),
              )
            else
              SoftHeader(
                title: 'サブスクリプション',
                // Menu (three dots) on the LEFT, settings gear on the RIGHT.
                leading: SoftIconButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => showSubscriptionSettingsSheet(context),
                ),
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const SettingsScreen()),
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
                      if (!selection.active) ...[
                        _SummaryCard(active: active),
                        const Gap(AppSpacing.lg),
                      ],
                      _ListBody(
                        visible: visible,
                        manualSort: settings.sortMode == SortMode.manual,
                        selectionActive: selection.active,
                        selectedIds: selection.ids,
                        onTapTile: (s) => selection.active
                            ? selectionCtrl.toggle(s.id)
                            : _openForm(context, ref, existing: s),
                        onReorder: (list) =>
                            ref.read(subscriptionsProvider.notifier).reorder(list),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (selection.active)
              _DeleteBar(
                count: selection.count,
                onDelete: () => _confirmBulkDelete(context, ref, selection.ids),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBulkDelete(
      BuildContext context, WidgetRef ref, Set<String> ids) async {
    if (ids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${ids.length}件を削除しますか？'),
        content: const Text('選択したサブスクを削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(subscriptionsProvider.notifier).deleteMany(ids.toList());
    ref.read(homeSelectionProvider.notifier).exit();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${ids.length}件を削除しました')));
    }
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(label,
            style: AppType.body(14,
                weight: FontWeight.w700, color: AppAccent.of(context).deep)),
      ),
    );
  }
}

/// Bottom action bar shown in selection mode.
class _DeleteBar extends StatelessWidget {
  const _DeleteBar({required this.count, required this.onDelete});
  final int count;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
          AppSpacing.md + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: AppColors.canvas),
      child: SoftButton(
        label: count > 0 ? '$count件を削除' : '削除する項目を選択',
        icon: count > 0 ? Icons.delete_outline_rounded : null,
        kind: SoftButtonKind.danger,
        onPressed: count > 0 ? onDelete : null,
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
          // Auto-shrink so a very large total never overflows the card.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedCounter(
              value: total,
              formatter: (v) => fmt.format(v),
              style: AppType.display(34, color: AppColors.onPrimary),
            ),
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
    required this.selectionActive,
    required this.selectedIds,
    required this.onTapTile,
    required this.onReorder,
  });

  final List<Subscription> visible;
  final bool manualSort;
  final bool selectionActive;
  final Set<String> selectedIds;
  final void Function(Subscription) onTapTile;
  final void Function(List<Subscription>) onReorder;

  @override
  Widget build(BuildContext context) {
    // Selection mode: a plain, non-reorderable list with a check per tile.
    if (selectionActive) {
      return Column(
        children: [
          for (final s in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SelectableTile(
                sub: s,
                selected: selectedIds.contains(s.id),
                onTap: () => onTapTile(s),
              ),
            ),
        ],
      );
    }
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

/// A subscription tile with a leading checkbox for multi-select. Tapping
/// anywhere toggles selection (the tile itself doesn't handle the tap).
class _SelectableTile extends StatelessWidget {
  const _SelectableTile(
      {required this.sub, required this.selected, required this.onTap});
  final Subscription sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppAccent.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? accent.primary : AppColors.textMuted,
            size: 26,
          ),
          const Gap(AppSpacing.sm),
          Expanded(child: IgnorePointer(child: SubscriptionTile(sub: sub))),
        ],
      ),
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
