import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/subscription_avatar.dart';
import '../../data/models/reminder_fire.dart';
import '../../providers/core_providers.dart';
import '../../providers/subscription_providers.dart';

/// Guarantees that a payment reminder is shown **while the app is open**.
///
/// OS notifications are unreliable in the foreground (iOS suppresses them by
/// default and Focus modes / per-app settings can hide them), so instead of
/// relying on the OS, this wraps the whole app and shows our own in-app banner
/// exactly when a reminder is due. The OS notifications still cover the
/// background/closed case. Wrap the app via `MaterialApp.builder` so the banner
/// floats above every screen.
class ForegroundReminderHost extends ConsumerStatefulWidget {
  const ForegroundReminderHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ForegroundReminderHost> createState() =>
      _ForegroundReminderHostState();
}

class _ForegroundReminderHostState extends ConsumerState<ForegroundReminderHost>
    with WidgetsBindingObserver {
  Timer? _timer;
  // Reminders already shown this session (id|fireTime) so they fire once.
  final Set<String> _shown = {};
  ReminderFire? _active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleNext());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Timers don't run reliably in the background; recompute on resume so a
    // reminder that came due while away is picked up (or correctly skipped as
    // already-past — the OS notification handled it while backgrounded).
    if (state == AppLifecycleState.resumed) {
      _scheduleNext();
      // The user is back in the app: clear the icon badge and reschedule so the
      // pending notifications' baked-in badge numbers restart from 1 (delivered
      // ones are past their fire-time and simply drop out). Fire-and-forget.
      final subs = ref.read(subscriptionsProvider).valueOrNull ?? const [];
      ref.read(notificationServiceProvider).rescheduleAll(subs);
    }
  }

  /// All reminder fire-times still in the future, soonest first. Driven purely
  /// by each subscription's own notify rules (no app-wide on/off gate).
  List<ReminderFire> _upcoming(DateTime now) {
    final subs = ref.read(subscriptionsProvider).valueOrNull ?? const [];
    return computeUpcomingReminders(subs, now);
  }

  void _scheduleNext() {
    _timer?.cancel();
    final now = DateTime.now();
    final upcoming = _upcoming(now);
    if (upcoming.isEmpty) return;
    final next = upcoming.first;
    final delay = next.fireAt.difference(now);
    // Cap long waits and re-arm periodically so we stay accurate over time.
    final capped = delay > const Duration(hours: 6)
        ? const Duration(hours: 6)
        : delay + const Duration(milliseconds: 300);
    _timer = Timer(capped, () {
      if (!mounted) return;
      if (!DateTime.now().isBefore(next.fireAt) && !_shown.contains(next.key)) {
        _shown.add(next.key);
        HapticFeedback.heavyImpact();
        setState(() => _active = next);
      }
      _scheduleNext();
    });
  }

  void _dismiss() {
    if (mounted) setState(() => _active = null);
  }

  @override
  Widget build(BuildContext context) {
    // Re-arm whenever the data that determines fire-times changes.
    ref.listen(subscriptionsProvider, (_, __) => _scheduleNext());

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(child: widget.child),
        if (_active != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ReminderBanner(
              key: ValueKey(_active!.key),
              reminder: _active!,
              onDismiss: _dismiss,
            ),
          ),
      ],
    );
  }
}

/// The floating top banner: slides in, auto-dismisses after a few seconds, and
/// dismisses on tap.
class _ReminderBanner extends StatefulWidget {
  const _ReminderBanner({super.key, required this.reminder, required this.onDismiss});
  final ReminderFire reminder;
  final VoidCallback onDismiss;

  @override
  State<_ReminderBanner> createState() => _ReminderBannerState();
}

class _ReminderBannerState extends State<_ReminderBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _auto = Timer(const Duration(seconds: 6), _close);
  }

  Future<void> _close() async {
    _auto?.cancel();
    if (!mounted) return;
    await _c.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reminder;
    final amount = CurrencyFormatter(r.sub.currency).format(r.sub.amount);
    final due = r.due;
    final body = r.rule.daysBefore == 0
        ? '本日 ${due.month}月${due.day}日に $amount の支払いがあります'
        : '${due.month}月${due.day}日（${r.rule.daysBefore}日後）に $amount の支払いがあります';

    return SafeArea(
      bottom: false,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -1.2), end: Offset.zero)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _c,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GestureDetector(
              onTap: _close,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                  boxShadow: AppShadows.raised(intensity: 1.2),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    SubscriptionAvatar(sub: r.sub, size: 44, radius: 14),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications_active_rounded,
                                  size: 15, color: AppAccent.of(context).deep),
                              const Gap(4),
                              Expanded(
                                child: Text('${r.sub.name} の支払い',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppType.display(15)),
                              ),
                            ],
                          ),
                          const Gap(2),
                          Text(body,
                              style: AppType.body(12.5,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
