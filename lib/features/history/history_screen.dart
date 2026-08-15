import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/subscription_avatar.dart';
import '../../core/widgets/soft_header.dart';
import '../../data/models/subscription.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import '../subscription/subscription_form_screen.dart';
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
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const SettingsScreen()),
              ),
            ),
            // 月間 / 年間 shown as tabs (same position & style as the 分析 tab).
            _ScopeTabs(
              scope: _scope,
              onChanged: (s) => setState(() => _scope = s),
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
    final main = ref.watch(settingsProvider.select((s) => s.mainCurrency));
    final data = ref.watch(monthlyHistoryProvider(_year));
    final payments = ref.watch(monthPaymentsProvider(DateTime(_year, _month)));
    // Split the month's payments into what's already been billed and what's
    // still upcoming, for the 「支払い済み」/「支払い予定」 sections below.
    final paidRows = [for (final p in payments) if (p.paid) p];
    final upcomingRows = [for (final p in payments) if (!p.paid) p];
    // The headline total is what's actually been paid this month, matching the
    // colored (paid) portion of the bar and the 「支払い済み」 section.
    final monthTotal = data[_month - 1].paid;

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
            paidValues: [for (final d in data) d.paid],
            selectedIndex: _month - 1,
            onSelect: (i) => setState(() => _month = i + 1),
            accent: AppAccent.of(context).primary,
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child:
                        Text(fmt.format(monthTotal), style: AppType.display(26)),
                  ),
                ],
              ),
            ),
            _ArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => changeMonth(1)),
          ],
        ),
        const Gap(AppSpacing.xs),
        // ── 支払い済み ──
        const SectionHeader('支払い済み'),
        if (paidRows.isEmpty)
          _emptyCard('支払い済みアイテムはありません')
        else
          for (final p in paidRows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PaymentRow(
                sub: p.sub,
                subtitle: JpDate.short(p.date),
                amount: fmt.format(p.sub.amountIn(main)),
                original: p.sub.currency != main
                    ? CurrencyFormatter(p.sub.currency).format(p.sub.amount)
                    : null,
              ),
            ),
        // ── 支払い予定（未払い＝半透明） ──
        const SectionHeader('支払い予定'),
        if (upcomingRows.isEmpty)
          _emptyCard('支払い予定アイテムはありません')
        else
          for (final p in upcomingRows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PaymentRow(
                sub: p.sub,
                subtitle: JpDate.short(p.date),
                amount: fmt.format(p.sub.amountIn(main)),
                original: p.sub.currency != main
                    ? CurrencyFormatter(p.sub.currency).format(p.sub.amount)
                    : null,
                dimmed: true,
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
    // Headline = what's actually been paid this year, matching the list below.
    final selectedTotal = data
        .firstWhere((e) => e.year == _selectedYear,
            orElse: () => YearSpend(_selectedYear, 0, 0))
        .paid;

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
            paidValues: [for (final e in data) e.paid],
            selectedIndex: selectedIndex,
            onSelect: (i) => setState(() => _selectedYear = data[i].year),
            accent: AppAccent.of(context).primary,
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(fmt.format(selectedTotal),
                        style: AppType.display(26)),
                  ),
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

/// 月間 / 年間 tabs, matching the 分析 (analytics) tab's look and position.
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.scope, required this.onChanged});
  final HistoryScope scope;
  final ValueChanged<HistoryScope> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, HistoryScope s) {
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
                      color:
                          sel ? AppColors.textPrimary : AppColors.textMuted)),
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
        tab('月間', HistoryScope.month),
        tab('年間', HistoryScope.year),
      ]),
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
                  decoration: BoxDecoration(
                    color: AppAccent.of(context).primary,
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
    this.original,
    this.dimmed = false,
  });
  final Subscription sub;
  final String subtitle;

  /// メイン通貨に換算済みの整形済み文字列（主表示）。
  final String amount;

  /// 元通貨での額（メイン通貨と違うときだけ小さく併記）。null なら非表示。
  final String? original;

  /// Upcoming (not-yet-billed) rows render half-transparent to signal they
  /// haven't been paid yet.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final card = SoftCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      // Long-press jumps straight to the subscription's editor.
      onLongPress: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SubscriptionFormScreen(existing: sub),
      )),
      child: Row(
        children: [
          SubscriptionAvatar(sub: sub, size: 38, radius: 12),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(amount, style: AppType.display(16)),
              if (original != null)
                Text(original!,
                    style: AppType.body(11.5,
                        weight: FontWeight.w600, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
    return dimmed ? Opacity(opacity: 0.5, child: card) : card;
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
