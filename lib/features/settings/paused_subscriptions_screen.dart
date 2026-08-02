import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../core/utils/currency.dart';
import '../../providers/subscription_providers.dart';

class PausedSubscriptionsScreen extends ConsumerWidget {
  const PausedSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = (ref.watch(subscriptionsProvider).valueOrNull ?? const [])
        .where((s) => s.isPaused)
        .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: '停止中のサブスク',
              leading: SoftIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: paused.isEmpty
                  ? const SoftEmptyState(
                      icon: Icons.pause_circle_rounded,
                      title: '停止中のサブスクはありません',
                      message: '一時的に使わないサブスクは、\n編集画面から停止中にできます。',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, 40),
                      itemCount: paused.length,
                      separatorBuilder: (_, __) => const Gap(AppSpacing.md),
                      itemBuilder: (context, i) {
                        final s = paused[i];
                        final fmt = CurrencyFormatter(s.currency);
                        return SoftCard(
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: s.color.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Text(s.displayGlyph,
                                    style: const TextStyle(fontSize: 20)),
                              ),
                              const Gap(AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: AppType.body(15.5, weight: FontWeight.w700)),
                                    Text('${fmt.format(s.amount)} /${s.periodLabel}',
                                        style: AppType.body(12,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              SoftButton(
                                label: '再開',
                                expand: false,
                                height: 40,
                                kind: SoftButtonKind.neutral,
                                onPressed: () => ref
                                    .read(subscriptionsProvider.notifier)
                                    .setPaused(s.id, false),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
