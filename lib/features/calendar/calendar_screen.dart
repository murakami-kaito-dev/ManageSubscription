import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/billing.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../data/models/subscription.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_providers.dart';
import '../premium/premium_screen.dart';
import '../settings/settings_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  bool _isCurrentMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  List<Subscription> _paymentsOn(DateTime day, List<Subscription> subs) {
    final target = DateTime(day.year, day.month, day.day);
    return subs.where((s) {
      if (s.isPaused) return false;
      final list = Billing.paymentsInRange(
          s.firstPaymentDate, s.cycle, target, target);
      return list.isNotEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final subs = (ref.watch(subscriptionsProvider).valueOrNull ?? const [])
        .where((s) => !s.isPaused)
        .toList();
    final isPremium = ref.watch(premiumProvider);
    final fmt = ref.watch(mainCurrencyFormatterProvider);
    final currency = ref.watch(settingsProvider).mainCurrency;

    // Total billed in the focused month (main currency).
    final monthStart = DateTime(_focused.year, _focused.month, 1);
    final monthEnd = DateTime(_focused.year, _focused.month + 1, 0);
    double monthTotal = 0;
    for (final s in subs) {
      final payments = Billing.paymentsInRange(
          s.firstPaymentDate, s.cycle, monthStart, monthEnd);
      monthTotal += payments.length * s.amountIn(currency);
    }

    final selectedPayments = _paymentsOn(_selected, subs);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: 'カレンダー',
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Text(DateFormat('yyyy年M月').format(_focused),
                      style: AppType.display(22)),
                  const Spacer(),
                  Text(fmt.format(monthTotal), style: AppType.display(22)),
                ],
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 40),
                children: [
                  SoftCard(
                    child: TableCalendar<Subscription>(
                      firstDay: DateTime.utc(2015, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: _focused,
                      currentDay: DateTime.now(),
                      selectedDayPredicate: (d) => isSameDay(d, _selected),
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      headerVisible: false,
                      daysOfWeekHeight: 26,
                      rowHeight: 46,
                      eventLoader: (day) => _paymentsOn(day, subs),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selected = selected;
                          _focused = focused;
                        });
                      },
                      onPageChanged: (focused) {
                        // Free tier: only the current month is viewable.
                        if (!isPremium && !_isCurrentMonth(focused)) {
                          PremiumScreen.show(context,
                              reason: '過去・未来のカレンダー閲覧はプレミアム機能です。');
                          setState(() => _focused = DateTime.now());
                          return;
                        }
                        setState(() => _focused = focused);
                      },
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle:
                            AppType.body(14, color: AppColors.coral),
                        defaultTextStyle: AppType.body(14),
                        todayDecoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: AppType.body(14,
                            weight: FontWeight.w700,
                            color: AppColors.primaryDeep),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: AppType.body(14,
                            weight: FontWeight.w700, color: AppColors.onPrimary),
                        markersMaxCount: 4,
                        markerDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        markerSize: 5,
                        markerMargin:
                            const EdgeInsets.symmetric(horizontal: 1),
                      ),
                      calendarBuilders: CalendarBuilders<Subscription>(
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) return null;
                          return Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final e in events.take(4))
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: e.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: AppType.body(12,
                            weight: FontWeight.w600,
                            color: AppColors.textSecondary),
                        weekendStyle: AppType.body(12,
                            weight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                  Row(
                    children: [
                      Text(DateFormat('M月d日').format(_selected),
                          style: AppType.display(17)),
                      const Spacer(),
                      if (selectedPayments.isNotEmpty)
                        Text(
                          fmt.format(selectedPayments.fold<double>(
                              0, (sum, s) => sum + s.amountIn(currency))),
                          style: AppType.display(17, color: AppColors.primaryDeep),
                        ),
                    ],
                  ),
                  const Gap(AppSpacing.sm),
                  if (selectedPayments.isEmpty)
                    SoftCard(
                      child: Center(
                        child: Text('この日の支払いはありません',
                            style: AppType.body(13,
                                color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    for (final s in selectedPayments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _PaymentRow(sub: s, currency: currency),
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

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.sub, required this.currency});
  final Subscription sub;
  final AppCurrency currency;

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
            child: Text(sub.emoji ?? sub.name.characters.first,
                style: const TextStyle(fontSize: 18)),
          ),
          const Gap(AppSpacing.md),
          Expanded(child: Text(sub.name, style: AppType.body(15, weight: FontWeight.w700))),
          Text(CurrencyFormatter(sub.currency).format(sub.amount),
              style: AppType.display(16)),
        ],
      ),
    );
  }
}
