import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import '../premium/premium_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/history_bar_chart.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    final fmt = ref.watch(mainCurrencyFormatterProvider);
    final data = ref.watch(monthlyHistoryProvider(_year));
    final payments =
        ref.watch(monthPaymentsProvider(DateTime(_year, _month)));
    final monthTotal = data[_month - 1].amount;

    void guardYearChange(int delta) {
      if (!isPremium) {
        PremiumScreen.show(context, reason: '過去・未来の履歴閲覧はプレミアム機能です。');
        return;
      }
      setState(() => _year += delta);
    }

    void changeMonth(int delta) {
      var m = _month + delta;
      var y = _year;
      if (m < 1) {
        m = 12;
        y -= 1;
      } else if (m > 12) {
        m = 1;
        y += 1;
      }
      if (!isPremium && y != DateTime.now().year) {
        PremiumScreen.show(context, reason: '過去・未来の履歴閲覧はプレミアム機能です。');
        return;
      }
      setState(() {
        _month = m;
        _year = y;
      });
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: '支払い履歴',
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 40),
                children: [
                  Center(
                    child: Pressable(
                      onTap: () => guardYearChange(0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$_year年', style: AppType.display(22)),
                          if (!isPremium) ...[
                            const Gap(4),
                            const Icon(Icons.lock_rounded,
                                size: 16, color: AppColors.textMuted),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                  SoftCard(
                    child: HistoryBarChart(
                      data: data,
                      selectedMonth: _month,
                      onSelect: (m) => setState(() => _month = m),
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                  Row(
                    children: [
                      _ArrowButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => changeMonth(-1)),
                      Expanded(
                        child: Column(
                          children: [
                            Text('$_month月',
                                style: AppType.body(14,
                                    color: AppColors.textSecondary)),
                            const Gap(2),
                            Text(fmt.format(monthTotal),
                                style: AppType.display(26)),
                          ],
                        ),
                      ),
                      _ArrowButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => changeMonth(1)),
                    ],
                  ),
                  const Gap(AppSpacing.lg),
                  if (payments.isEmpty)
                    SoftCard(
                      child: Center(
                        child: Text('この月の支払いはありません',
                            style: AppType.body(13,
                                color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    for (final p in payments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: SoftCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: p.sub.color.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                    p.sub.emoji ?? p.sub.name.characters.first,
                                    style: const TextStyle(fontSize: 18)),
                              ),
                              const Gap(AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.sub.name,
                                        style: AppType.body(15,
                                            weight: FontWeight.w700)),
                                    Text(DateFormat('yyyy年M月d日').format(p.date),
                                        style: AppType.body(11.5,
                                            color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Text(
                                  CurrencyFormatter(p.sub.currency)
                                      .format(p.sub.amount),
                                  style: AppType.display(16)),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.surfaceSunken,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textSecondary),
      ),
    );
  }
}
