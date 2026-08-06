import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../core/widgets/subscription_avatar.dart';
import '../../providers/subscription_providers.dart';
import '../../services/csv/csv_import_service.dart';

/// Preview of a parsed CSV. Nothing is written until the user taps 取り込む, and
/// even then it is purely additive — existing data is never touched.
class CsvImportPreviewScreen extends ConsumerStatefulWidget {
  const CsvImportPreviewScreen({super.key, required this.result});
  final CsvImportResult result;

  @override
  ConsumerState<CsvImportPreviewScreen> createState() =>
      _CsvImportPreviewScreenState();
}

class _CsvImportPreviewScreenState
    extends ConsumerState<CsvImportPreviewScreen> {
  bool _saving = false;

  Future<void> _import() async {
    final valid = widget.result.valid;
    if (valid.isEmpty || _saving) return;
    setState(() => _saving = true);
    await ref.read(subscriptionsProvider.notifier).saveAll(valid);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${valid.length}件を追加しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: 'CSVインポート',
              leading: SoftIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 40),
                children: [
                  if (r.hasFatal)
                    _MessageCard(
                      icon: Icons.error_outline_rounded,
                      color: AppColors.danger,
                      title: '読み込めませんでした',
                      body: r.fatal!,
                    )
                  else ...[
                    _SummaryCard(valid: r.validCount, errors: r.errorCount),
                    if (r.validCount > 0) ...[
                      const Gap(AppSpacing.lg),
                      Text('追加される項目（${r.validCount}件）',
                          style: AppType.body(13,
                              weight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                      const Gap(AppSpacing.sm),
                      for (final s in r.valid)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: SoftCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md),
                            child: Row(
                              children: [
                                SubscriptionAvatar(sub: s, size: 38, radius: 12),
                                const Gap(AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppType.body(15,
                                              weight: FontWeight.w700)),
                                      Text(JpDate.short(s.firstPaymentDate),
                                          style: AppType.body(11.5,
                                              color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${CurrencyFormatter(s.currency).format(s.amount)} /${s.periodLabel}',
                                  style: AppType.display(15),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    if (r.errorCount > 0) ...[
                      const Gap(AppSpacing.lg),
                      Text('スキップされた項目（${r.errorCount}件）',
                          style: AppType.body(13,
                              weight: FontWeight.w700,
                              color: AppColors.danger)),
                      const Gap(AppSpacing.sm),
                      // One boxed group per item: its name (◯行目) + every error.
                      for (final e in r.errors)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ErrorGroup(error: e),
                        ),
                    ],
                  ],
                ],
              ),
            ),
            if (!r.hasFatal)
              Container(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md + MediaQuery.of(context).padding.bottom),
                decoration: const BoxDecoration(color: AppColors.canvas),
                child: SoftButton(
                  label: _saving
                      ? '追加中…'
                      : (r.validCount > 0
                          ? '${r.validCount}件を取り込む'
                          : '取り込める項目がありません'),
                  icon: _saving ? null : Icons.download_rounded,
                  onPressed: (r.validCount == 0 || _saving) ? null : _import,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.valid, required this.errors});
  final int valid;
  final int errors;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
              const Gap(AppSpacing.sm),
              Text('取り込み可能：$valid件', style: AppType.display(16)),
            ],
          ),
          if (errors > 0) ...[
            const Gap(AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 20),
                const Gap(AppSpacing.sm),
                Text('スキップ：$errors件', style: AppType.body(14)),
              ],
            ),
          ],
          const Gap(AppSpacing.md),
          Text('既存のデータは削除・変更されません。上記の項目が新規追加されます。',
              style: AppType.body(12,
                  color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

/// A boxed group for one rejected row: "Item（◯行目）" then each problem.
class _ErrorGroup extends StatelessWidget {
  const _ErrorGroup({required this.error});
  final CsvRowError error;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 18),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(error.heading,
                    style: AppType.body(14, weight: FontWeight.w800)),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          for (final m in error.messages)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 26),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('・',
                      style: AppType.body(12.5, color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(m,
                        style: AppType.body(12.5,
                            color: AppColors.textSecondary, height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const Gap(AppSpacing.sm),
              Text(title, style: AppType.display(16)),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(body,
              style: AppType.body(13,
                  color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
