import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/preset_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../../cancellation/cancel_guide_data.dart';

/// プリセットアイコン（スケッチ風・48種）を選ぶボトムシート。
/// 収録とカテゴリは「解約方法」タブ（[kCancelGuideEntries]）と共通。
/// 選ばれたら `preset:<id>` を返す（キャンセル時は null）。
Future<String?> showPresetIconSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    builder: (_) => const _PresetIconSheet(),
  );
}

class _PresetIconSheet extends StatelessWidget {
  const _PresetIconSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            const Gap(AppSpacing.md),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Gap(AppSpacing.lg),
            Text('アイコンから選ぶ', style: AppType.display(18)),
            const Gap(AppSpacing.xs),
            Text('主要サービスのオリジナルアイコンを用意しています',
                style: AppType.body(12, color: AppColors.textSecondary)),
            const Gap(AppSpacing.md),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 32),
                children: [
                  for (final section in cancelGuideSections()) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: AppSpacing.md, bottom: AppSpacing.sm),
                      child: Text(section.category.label,
                          style: AppType.body(12,
                              weight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                    ),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.78,
                      children: [
                        for (final e in section.entries)
                          _PresetCell(entry: e),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCell extends StatelessWidget {
  const _PresetCell({required this.entry});

  final CancelGuideEntry entry;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.of(context).pop(PresetIcons.keyFor(entry.id)),
      scale: 0.9,
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/preset_icons/${entry.id}.svg',
            width: 56,
            height: 56,
          ),
          const Gap(4),
          Text(
            entry.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppType.body(10, color: AppColors.textSecondary, height: 1.2),
          ),
        ],
      ),
    );
  }
}
