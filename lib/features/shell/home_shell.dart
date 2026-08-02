import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pressable.dart';
import '../analytics/analytics_screen.dart';
import '../calendar/calendar_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import 'banner_ad_slot.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'ホーム'),
    (icon: Icons.pie_chart_rounded, label: '分析'),
    (icon: Icons.calendar_today_rounded, label: 'カレンダー'),
    (icon: Icons.bar_chart_rounded, label: '支払い履歴'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          AnalyticsScreen(),
          CalendarScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdSlot(),
          _SoftNavBar(
            index: _index,
            tabs: _tabs,
            onTap: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }
}

class _SoftNavBar extends StatelessWidget {
  const _SoftNavBar({
    required this.index,
    required this.tabs,
    required this.onTap,
  });

  final int index;
  final List<({IconData icon, String label})> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppShadows.raised(),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: tabs[i].icon,
                    label: tabs[i].label,
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDeep : AppColors.textMuted;
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.body(10,
                  weight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
