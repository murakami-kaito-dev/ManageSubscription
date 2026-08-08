import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/premium_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/subscription_avatar.dart';
import '../../data/models/category.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/subscription.dart';
import '../../providers/premium_provider.dart';
import '../../providers/subscription_providers.dart';
import 'premium_screen.dart';

/// Wraps the app shell. When a **free** user holds more items than the free
/// plan allows (e.g. after a subscription lapses), the whole app is replaced by
/// a screen that lets them either upgrade (unlocks instantly) or trim the extras
/// in place. It clears itself the moment they're back under the limits — so it's
/// never a dead end.
class LimitGate extends ConsumerWidget {
  const LimitGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(premiumProvider)) return child;
    final subs = ref.watch(subscriptionsProvider).valueOrNull ?? const [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final pays = ref.watch(paymentMethodsProvider).valueOrNull ?? const [];
    final over = subs.length > PremiumLimits.maxSubscriptions ||
        cats.length > PremiumLimits.maxCategories ||
        pays.length > PremiumLimits.maxPaymentMethods;
    if (!over) return child;
    return _GateScreen(subs: subs, cats: cats, pays: pays);
  }
}

class _GateScreen extends ConsumerWidget {
  const _GateScreen(
      {required this.subs, required this.cats, required this.pays});
  final List<Subscription> subs;
  final List<Category> cats;
  final List<PaymentMethod> pays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subOver = subs.length - PremiumLimits.maxSubscriptions;
    final catOver = cats.length - PremiumLimits.maxCategories;
    final payOver = pays.length - PremiumLimits.maxPaymentMethods;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
          children: [
            const Gap(AppSpacing.md),
            const Icon(Icons.lock_rounded, color: AppColors.gold, size: 40),
            const Gap(AppSpacing.md),
            Text('無料プランの上限を超えています',
                textAlign: TextAlign.center, style: AppType.display(20)),
            const Gap(AppSpacing.sm),
            Text(
              '無料プランで使えるのは サブスク${PremiumLimits.maxSubscriptions}件 / '
              'カテゴリー${PremiumLimits.maxCategories}件 / '
              '支払い方法${PremiumLimits.maxPaymentMethods}件 までです。\n'
              '超えている分を減らすか、プレミアムに登録すると続けて使えます。',
              textAlign: TextAlign.center,
              style:
                  AppType.body(13, color: AppColors.textSecondary, height: 1.6),
            ),
            const Gap(AppSpacing.lg),
            SoftButton(
              label: 'プレミアムに登録して解除',
              icon: Icons.workspace_premium_rounded,
              onPressed: () => PremiumScreen.show(context),
            ),
            const Gap(AppSpacing.xs),
            Pressable(
              onTap: () => ref.read(premiumProvider.notifier).restore(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('購入を復元',
                    textAlign: TextAlign.center,
                    style: AppType.body(13,
                        weight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ),
            ),
            const Gap(AppSpacing.md),
            if (subOver > 0)
              _OverSection(
                title: 'サブスク',
                over: subOver,
                current: subs.length,
                max: PremiumLimits.maxSubscriptions,
                children: [
                  for (final s in subs)
                    _Row(
                      leading: SubscriptionAvatar(sub: s, size: 34, radius: 10),
                      title: s.name,
                      trailingText:
                          CurrencyFormatter(s.currency).format(s.amount),
                      onDelete: () => _confirmDelete(context, s.name,
                          () => ref
                              .read(subscriptionsProvider.notifier)
                              .delete(s.id)),
                    ),
                ],
              ),
            if (catOver > 0)
              _OverSection(
                title: 'カテゴリー',
                over: catOver,
                current: cats.length,
                max: PremiumLimits.maxCategories,
                children: [
                  for (final c in cats)
                    _Row(
                      leading: _IconChip(icon: c.iconData, color: c.color),
                      title: c.name,
                      canDelete: !c.isBuiltIn,
                      onDelete: () => _confirmDelete(context, c.name,
                          () => ref
                              .read(categoriesProvider.notifier)
                              .delete(c.id)),
                    ),
                ],
              ),
            if (payOver > 0)
              _OverSection(
                title: '支払い方法',
                over: payOver,
                current: pays.length,
                max: PremiumLimits.maxPaymentMethods,
                children: [
                  for (final m in pays)
                    _Row(
                      leading: _IconChip(icon: m.iconData, color: m.color),
                      title: m.name,
                      canDelete: !m.isBuiltIn,
                      onDelete: () => _confirmDelete(context, m.name,
                          () => ref
                              .read(paymentMethodsProvider.notifier)
                              .delete(m.id)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String name, VoidCallback onOk) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('「$name」を削除しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) onOk();
  }
}

class _OverSection extends StatelessWidget {
  const _OverSection({
    required this.title,
    required this.over,
    required this.current,
    required this.max,
    required this.children,
  });
  final String title;
  final int over;
  final int current;
  final int max;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('$title（$current / $max件）',
                      style: AppType.display(15)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coralSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('あと$over件減らす',
                      style: AppType.body(11.5,
                          weight: FontWeight.w800, color: AppColors.coral)),
                ),
              ],
            ),
            const Gap(AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.leading,
    required this.title,
    required this.onDelete,
    this.trailingText,
    this.canDelete = true,
  });
  final Widget leading;
  final String title;
  final VoidCallback onDelete;
  final String? trailingText;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          leading,
          const Gap(AppSpacing.md),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body(14.5)),
          ),
          if (trailingText != null) ...[
            Text(trailingText!,
                style: AppType.body(13, color: AppColors.textMuted)),
            const Gap(AppSpacing.sm),
          ],
          if (canDelete)
            Pressable(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.lock_outline_rounded,
                  size: 18, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}
