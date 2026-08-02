import 'dart:ui' as ui;

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
import '../../data/models/subscription.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import '../premium/premium_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/history_bar_chart.dart';

enum HistoryScope { month, year }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryScope _scope = HistoryScope.month;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  int _yearWindowEnd = DateTime.now().year; // last year shown on the year chart
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);

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
              trailing: _ScopeToggle(
                scope: _scope,
                onChanged: (s) => setState(() => _scope = s),
              ),
            ),
            Expanded(
              child: _scope == HistoryScope.month
                  ? _buildMonthView(isPremium)
                  : (isPremium
                      ? _buildYearView()
                      : _LockedYearPreview(
                          endYear: _yearWindowEnd,
                          onUnlock: () => PremiumScreen.show(context,
                              reason: '年間の支払い履歴はプレミアム機能です。'),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  // ── Monthly view ─────────────────────────────────────────────────────────
  Widget _buildMonthView(bool isPremium) {
    final fmt = ref.watch(mainCurrencyFormatterProvider);
    final data = ref.watch(monthlyHistoryProvider(_year));
    final payments = ref.watch(monthPaymentsProvider(DateTime(_year, _month)));
    final monthTotal = data[_month - 1].amount;

    void guardYearChange() {
      if (!isPremium) {
        PremiumScreen.show(context, reason: '過去・未来の履歴閲覧はプレミアム機能です。');
        return;
      }
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

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 40),
      children: [
        Center(
          child: Pressable(
            onTap: guardYearChange,
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
            labels: [for (var m = 1; m <= 12; m++) '$m'],
            values: [for (final d in data) d.amount],
            selectedIndex: _month - 1,
            onSelect: (i) => setState(() => _month = i + 1),
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
                      style: AppType.body(14, color: AppColors.textSecondary)),
                  const Gap(2),
                  Text(fmt.format(monthTotal), style: AppType.display(26)),
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
          _emptyCard('この月の支払いはありません')
        else
          for (final p in payments)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PaymentRow(
                sub: p.sub,
                subtitle: DateFormat('yyyy年M月d日').format(p.date),
                amount: CurrencyFormatter(p.sub.currency).format(p.sub.amount),
              ),
            ),
      ],
    );
  }

  // ── Yearly view (premium) ─────────────────────────────────────────────────
  Widget _buildYearView() {
    final fmt = ref.watch(mainCurrencyFormatterProvider);
    const count = 6;
    final data =
        ref.watch(yearlyHistoryProvider((endYear: _yearWindowEnd, count: count)));
    final rows = ref.watch(yearSubscriptionTotalsProvider(_selectedYear));
    final selectedIndex =
        data.indexWhere((e) => e.year == _selectedYear).clamp(0, count - 1);
    final selectedTotal =
        data.firstWhere((e) => e.year == _selectedYear, orElse: () => YearSpend(_selectedYear, 0)).amount;

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 40),
      children: [
        Center(child: Text('$_selectedYear年', style: AppType.display(22))),
        const Gap(AppSpacing.lg),
        SoftCard(
          child: HistoryBarChart(
            labels: [for (final e in data) "'${e.year % 100}"],
            values: [for (final e in data) e.amount],
            selectedIndex: selectedIndex,
            onSelect: (i) => setState(() => _selectedYear = data[i].year),
          ),
        ),
        const Gap(AppSpacing.lg),
        Row(
          children: [
            _ArrowButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => setState(() {
                _selectedYear -= 1;
                if (_selectedYear < _yearWindowEnd - count + 1) {
                  _yearWindowEnd -= 1;
                }
              }),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('$_selectedYear年の合計',
                      style: AppType.body(14, color: AppColors.textSecondary)),
                  const Gap(2),
                  Text(fmt.format(selectedTotal), style: AppType.display(26)),
                ],
              ),
            ),
            _ArrowButton(
              icon: Icons.chevron_right_rounded,
              onTap: () => setState(() {
                _selectedYear += 1;
                if (_selectedYear > _yearWindowEnd) _yearWindowEnd += 1;
              }),
            ),
          ],
        ),
        const Gap(AppSpacing.lg),
        if (rows.isEmpty)
          _emptyCard('この年の支払いはありません')
        else
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PaymentRow(
                sub: r.sub,
                subtitle: '年${r.count}回',
                amount: fmt.format(r.total),
              ),
            ),
      ],
    );
  }

  Widget _emptyCard(String text) => SoftCard(
        child: Center(
          child: Text(text,
              style: AppType.body(13, color: AppColors.textSecondary)),
        ),
      );
}

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.scope, required this.onChanged});
  final HistoryScope scope;
  final ValueChanged<HistoryScope> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, HistoryScope s) {
      final sel = scope == s;
      return Pressable(
        onTap: () => onChanged(s),
        scale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: AppType.body(12.5,
                  weight: FontWeight.w700,
                  color: sel ? AppColors.onPrimary : AppColors.textSecondary)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('月間', HistoryScope.month),
          seg('年間', HistoryScope.year),
        ],
      ),
    );
  }
}

/// The blurred, locked preview shown for the yearly view on the free tier.
class _LockedYearPreview extends ConsumerWidget {
  const _LockedYearPreview({required this.endYear, required this.onUnlock});
  final int endYear;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        ref.watch(yearlyHistoryProvider((endYear: endYear, count: 6)));
    return Stack(
      fit: StackFit.expand,
      children: [
        // Real chart, blurred, non-interactive.
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: Column(
                children: [
                  Text('$endYear年', style: AppType.display(22)),
                  const Gap(AppSpacing.lg),
                  SoftCard(
                    child: HistoryBarChart(
                      labels: [for (final e in data) "'${e.year % 100}"],
                      values: [for (final e in data) e.amount],
                      selectedIndex: data.length - 1,
                      onSelect: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(color: AppColors.canvas.withOpacity(0.35)),
        Center(
          child: Pressable(
            onTap: onUnlock,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AppColors.onPrimary, size: 30),
                ),
                const Gap(AppSpacing.md),
                Text('プレミアム機能', style: AppType.display(18)),
                const Gap(AppSpacing.xs),
                Text('年間の支払い履歴を見る',
                    style:
                        AppType.body(13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.sub,
    required this.subtitle,
    required this.amount,
  });
  final Subscription sub;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sub.color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(sub.displayGlyph,
                style: const TextStyle(fontSize: 18)),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.name,
                    style: AppType.body(15, weight: FontWeight.w700)),
                Text(subtitle,
                    style: AppType.body(11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(amount, style: AppType.display(16)),
        ],
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
