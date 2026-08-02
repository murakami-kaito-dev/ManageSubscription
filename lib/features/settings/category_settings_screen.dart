import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/icon_registry.dart';
import '../../core/premium_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../data/models/category.dart';
import '../../providers/premium_provider.dart';
import '../../providers/subscription_providers.dart';
import '../premium/premium_screen.dart';

class CategorySettingsScreen extends ConsumerWidget {
  const CategorySettingsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, {Category? existing}) async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    if (existing == null) {
      final isPremium = ref.read(premiumProvider);
      if (!PremiumLimits.canAddCategory(isPremium, categories.length)) {
        PremiumScreen.show(context,
            reason: '無料版のカテゴリーは${PremiumLimits.maxCategories}件までです。');
        return;
      }
    }
    final result = await showDialog<Category>(
      context: context,
      builder: (_) => CategoryEditorDialog(
        existing: existing,
        index: categories.length,
        existingNames: [
          for (final c in categories)
            if (c.id != existing?.id) c.name,
        ],
      ),
    );
    if (result != null) {
      await ref.read(categoriesProvider.notifier).save(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: 'カテゴリー設定',
              onSettings: null,
              trailing: SoftIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 40),
                children: [
                  if (!isPremium)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '無料版：${categories.length}/${PremiumLimits.maxCategories} 件',
                        style: AppType.body(12, color: AppColors.textMuted),
                      ),
                    ),
                  for (final c in categories) ...[
                    SoftCard(
                      onTap: () => _edit(context, ref, existing: c),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: c.color.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(c.iconData, color: c.color),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                              child: Text(c.name, style: AppType.body(15.5))),
                          Pressable(
                            onTap: () => ref
                                .read(categoriesProvider.notifier)
                                .delete(c.id),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Gap(AppSpacing.md),
                  ],
                  SoftButton(
                    label: 'カテゴリーを追加',
                    icon: Icons.add_rounded,
                    kind: SoftButtonKind.neutral,
                    onPressed: () => _edit(context, ref),
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

class CategoryEditorDialog extends StatefulWidget {
  const CategoryEditorDialog({
    super.key,
    this.existing,
    required this.index,
    this.existingNames = const [],
  });
  final Category? existing;
  final int index;

  /// Names of the other categories, used to block duplicates.
  final List<String> existingNames;

  @override
  State<CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<CategoryEditorDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  String? _error;
  late int _color =
      widget.existing?.colorValue ?? AppColors.chartPalette.first.value;
  late int _icon = widget.existing?.icon ?? _icons.first.codePoint;

  static const _icons = IconRegistry.categoryIcons;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
      title: Text(widget.existing == null ? 'カテゴリーを追加' : 'カテゴリーを編集',
          style: AppType.display(19)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: '名前',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const Gap(AppSpacing.lg),
            const SectionHeader('アイコン'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ic in _icons)
                  Pressable(
                    scale: 0.85,
                    onTap: () => setState(() => _icon = ic.codePoint),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _icon == ic.codePoint
                            ? Color(_color).withOpacity(0.2)
                            : AppColors.surfaceSunken,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _icon == ic.codePoint
                              ? Color(_color)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(ic,
                          size: 20,
                          color: _icon == ic.codePoint
                              ? Color(_color)
                              : AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
            const Gap(AppSpacing.lg),
            const SectionHeader('カラー'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final col in AppColors.chartPalette)
                  Pressable(
                    scale: 0.85,
                    onTap: () => setState(() => _color = col.value),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == col.value
                              ? AppColors.textPrimary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル')),
        TextButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              setState(() => _error = '名前を入力してください');
              return;
            }
            final exists = widget.existingNames
                .any((n) => n.trim().toLowerCase() == name.toLowerCase());
            if (exists) {
              setState(() => _error = '「$name」はすでに存在します');
              return;
            }
            Navigator.pop(
              context,
              Category(
                id: widget.existing?.id ?? const Uuid().v4(),
                name: name,
                colorValue: _color,
                icon: _icon,
                sortOrder: widget.existing?.sortOrder ?? widget.index,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
