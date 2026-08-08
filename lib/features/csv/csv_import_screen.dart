import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/premium_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../core/widgets/subscription_avatar.dart';
import '../../data/models/subscription.dart';
import '../../providers/subscription_providers.dart';
import '../../services/csv/csv_import_service.dart';
import 'csv_import_help_screen.dart';

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

  /// Ids the user has picked to import. Only used when the CSV would push the
  /// total over the 100-item cap (otherwise everything is imported as-is).
  final Set<String> _selectedIds = {};

  /// Free slots left before hitting the hard cap.
  int _remainingSlots() =>
      PremiumLimits.hardMaxSubscriptions - ref.read(subscriptionCountProvider);

  /// True when the valid rows don't all fit → the user must choose which to keep.
  bool _needsSelection(int remaining) =>
      remaining > 0 && widget.result.validCount > remaining;

  void _toggle(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  /// Select EVERY valid row — even beyond the cap. The import button then stays
  /// disabled until the user trims the selection down to the free slots.
  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(widget.result.valid.map((s) => s.id));
    });
  }

  void _clearAll() => setState(() => _selectedIds.clear());

  Future<void> _import() async {
    final valid = widget.result.valid;
    if (valid.isEmpty || _saving) return;

    // Respect the 100-item hard cap.
    final remaining = _remainingSlots();
    if (remaining <= 0) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('取り込めません'),
          content: const Text('登録できるサブスクは'
              '${PremiumLimits.hardMaxSubscriptions}件までです。'
              '不要なものを削除してからお試しください。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    // If everything fits, import all. Otherwise import only the user's picks —
    // but never more than the free slots (the button is disabled past that).
    final List<Subscription> toSave;
    if (_needsSelection(remaining)) {
      if (_selectedIds.isEmpty || _selectedIds.length > remaining) return;
      toSave = valid.where((s) => _selectedIds.contains(s.id)).toList();
    } else {
      toSave = valid;
    }

    setState(() => _saving = true);
    await ref.read(subscriptionsProvider.notifier).saveAll(toSave);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${toSave.length}件を追加しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final int remaining = PremiumLimits.hardMaxSubscriptions -
        ref.watch(subscriptionCountProvider);
    final selecting = _needsSelection(remaining);
    final full = remaining <= 0;
    final importCount = selecting ? _selectedIds.length : r.validCount;
    final overCap = selecting && importCount > remaining;
    final canImport = !full && !_saving && importCount > 0 && !overCap;

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
                  if (r.hasFatal) ...[
                    _MessageCard(
                      icon: Icons.error_outline_rounded,
                      color: AppColors.danger,
                      title: '読み込めませんでした',
                      body: r.fatal!,
                    ),
                    const Gap(AppSpacing.lg),
                    SoftButton(
                      label: 'CSVの書式を見る',
                      icon: Icons.help_outline_rounded,
                      kind: SoftButtonKind.neutral,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CsvImportHelpScreen()),
                      ),
                    ),
                  ] else ...[
                    _SummaryCard(valid: r.validCount, errors: r.errorCount),
                    if (r.validCount > 0) ...[
                      const Gap(AppSpacing.lg),
                      // Over the cap → let the user pick which rows to import
                      // (with 全選択/全解除); otherwise just list them all.
                      if (selecting)
                        _SelectionBar(
                          remaining: remaining,
                          selected: _selectedIds.length,
                          onSelectAll: _selectAll,
                          onClear: _clearAll,
                        )
                      else
                        Text('追加される項目（${r.validCount}件）',
                            style: AppType.body(13,
                                weight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                      const Gap(AppSpacing.sm),
                      for (final s in r.valid)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _validRow(
                            s,
                            selecting: selecting,
                            selected: _selectedIds.contains(s.id),
                            onTap: selecting ? () => _toggle(s.id) : null,
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
                      : full
                          ? 'これ以上追加できません（上限${PremiumLimits.hardMaxSubscriptions}件）'
                          : selecting
                              ? (importCount == 0
                                  ? '取り込む項目を選択してください'
                                  : overCap
                                      ? '選択を$remaining件以下にしてください'
                                      : '$importCount件を取り込む')
                              : (r.validCount > 0
                                  ? '${r.validCount}件を取り込む'
                                  : '取り込める項目がありません'),
                  icon: canImport ? Icons.download_rounded : null,
                  onPressed: canImport ? _import : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A valid CSV row. In selection mode it gets a leading check and the whole
  /// card becomes tappable to toggle.
  Widget _validRow(
    Subscription s, {
    required bool selecting,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final card = SoftCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          if (selecting) ...[
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const Gap(AppSpacing.md),
          ],
          SubscriptionAvatar(sub: s, size: 38, radius: 12),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body(15, weight: FontWeight.w700)),
                Text(JpDate.short(s.firstPaymentDate),
                    style: AppType.body(11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            '${CurrencyFormatter(s.currency).format(s.amount)} /${s.periodLabel}',
            style: AppType.display(15),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

/// Header shown when the CSV has more valid rows than free slots: explains the
/// cap and offers 全選択（上限まで）/ 全解除.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.remaining,
    required this.selected,
    required this.onSelectAll,
    required this.onClear,
  });
  final int remaining;
  final int selected;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final over = selected > remaining;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️取り込む項目を選択', style: AppType.display(15)),
          const Gap(AppSpacing.xs),
          Text(
            '登録できるのは合計${PremiumLimits.hardMaxSubscriptions}件までです。'
            'あと$remaining件まで選べます。',
            style:
                AppType.body(12, color: AppColors.textSecondary, height: 1.5),
          ),
          const Gap(AppSpacing.sm),
          Row(
            children: [
              TextButton(onPressed: onSelectAll, child: const Text('全選択')),
              TextButton(onPressed: onClear, child: const Text('全解除')),
              const Spacer(),
              // e.g. "120 / 97" — turns red when the pick exceeds the free slots.
              Text('$selected / $remaining',
                  style: AppType.body(13,
                      weight: FontWeight.w700,
                      color: over ? AppColors.danger : null)),
            ],
          ),
        ],
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
