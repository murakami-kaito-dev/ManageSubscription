import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/premium_crown.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../settings/category_settings_screen.dart';
import '../settings/payment_method_settings_screen.dart';
import '../settings/paused_subscriptions_screen.dart';

Future<void> showSubscriptionSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    builder: (_) => const _SubscriptionSettingsSheet(),
  );
}

class _SubscriptionSettingsSheet extends ConsumerWidget {
  const _SubscriptionSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.5,
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
                Text('サブスクリプション設定', style: AppType.display(21)),
                const Spacer(),
                Pressable(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const SectionHeader('表示'),
            _Card(children: [
              _SwitchRow(
                label: '停止中のサブスクリプションを表示',
                value: settings.showPaused,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setShowPaused(v),
              ),
            ]),
            const SectionHeader('管理'),
            _Card(children: [
              _NavRow(
                icon: Icons.folder_rounded,
                label: 'カテゴリー設定',
                onTap: () => _push(context, const CategorySettingsScreen()),
              ),
              const _Divider(),
              _NavRow(
                icon: Icons.account_balance_wallet_rounded,
                label: '支払い方法設定',
                onTap: () =>
                    _push(context, const PaymentMethodSettingsScreen()),
              ),
              const _Divider(),
              _NavRow(
                icon: Icons.pause_circle_rounded,
                label: '停止中のサブスクリプション',
                onTap: () => _push(context, const PausedSubscriptionsScreen()),
              ),
            ]),
            const SectionHeader('並べ替え'),
            _Card(
              children: [
                for (var i = 0; i < SortMode.values.length; i++) ...[
                  if (i > 0) const _Divider(),
                  _SortRow(
                    mode: SortMode.values[i],
                    selected: settings.sortMode == SortMode.values[i],
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .setSortMode(SortMode.values[i]),
                  ),
                ],
              ],
            ),
            const Gap(AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Divider(height: 1, color: AppColors.textMuted.withOpacity(0.18)),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppType.body(15))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryDeep),
            const Gap(AppSpacing.md),
            Expanded(child: Text(label, style: AppType.body(15))),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow(
      {required this.mode, required this.selected, required this.onTap});
  final SortMode mode;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        child: Row(
          children: [
            Expanded(
              child: Text(mode.label,
                  style: AppType.body(15,
                      weight: selected ? FontWeight.w700 : FontWeight.w500)),
            ),
            if (mode.isPremium) const PremiumCrown(size: 15),
            if (selected) ...[
              const Gap(AppSpacing.sm),
              const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
