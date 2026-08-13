import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pressable.dart';
import '../../providers/core_providers.dart';
import '../../providers/subscription_providers.dart';

/// Shown at the top of Home when the app has at least one active reminder rule
/// but the **OS** notification permission is off (denied or not yet granted).
///
/// This closes the silent-failure gap in the new notification model: reminders
/// are driven purely by each subscription's own rules, so the only remaining
/// reason a set reminder wouldn't fire is the OS permission — and this banner
/// makes that visible and one tap away from being fixed.
class NotificationPermissionBanner extends ConsumerStatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  ConsumerState<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends ConsumerState<NotificationPermissionBanner>
    with WidgetsBindingObserver {
  // Optimistic: assume granted until the async check says otherwise, so the
  // banner never flashes for users who have permission.
  bool _granted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when returning from the system Settings (they may have just
    // toggled the permission there).
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final granted = await ref.read(notificationServiceProvider).hasPermission();
    if (mounted) setState(() => _granted = granted);
  }

  Future<void> _enable() async {
    final service = ref.read(notificationServiceProvider);
    await service.requestPermission();
    final granted = await service.hasPermission();
    if (!mounted) return;
    if (granted) {
      setState(() => _granted = true);
      // Permission just came on — (re)schedule so pending reminders will fire.
      final subs = ref.read(subscriptionsProvider).valueOrNull ?? const [];
      await service.rescheduleAll(subs);
    } else {
      // Already denied at the OS level → guide them to Settings.
      await service.openSystemSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subscriptionsProvider).valueOrNull ?? const [];
    final hasActiveRules =
        subs.any((s) => !s.isPaused && s.notifyRules.isNotEmpty);
    if (_granted || !hasActiveRules) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Pressable(
        onTap: _enable,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
            border: Border.all(color: AppColors.gold.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_off_rounded,
                  color: AppColors.gold, size: 22),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('通知がオフになっています',
                        style: AppType.body(14, weight: FontWeight.w700)),
                    const Gap(2),
                    Text('支払日のお知らせを受け取るにはタップしてオンにしてください',
                        style: AppType.body(11.5,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
