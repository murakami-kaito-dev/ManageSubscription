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
import '../../core/widgets/delete_dialog.dart';
import '../../core/widgets/soft_header.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../data/models/payment_method.dart';
import '../../providers/premium_provider.dart';
import '../../providers/subscription_providers.dart';
import '../premium/premium_screen.dart';

class PaymentMethodSettingsScreen extends ConsumerWidget {
  const PaymentMethodSettingsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref,
      {PaymentMethod? existing}) async {
    final methods = ref.read(paymentMethodsProvider).valueOrNull ?? const [];
    if (existing == null) {
      final isPremium = ref.read(premiumProvider);
      if (!PremiumLimits.canAddPaymentMethod(isPremium, methods.length)) {
        PremiumScreen.show(context,
            reason: '無料版の支払い方法は${PremiumLimits.maxPaymentMethods}件までです。');
        return;
      }
    }
    final result = await showDialog<PaymentMethod>(
      context: context,
      builder: (_) => PaymentMethodEditorDialog(
        existing: existing,
        index: methods.length,
        nameEditable: existing == null || !existing.isBuiltIn,
        existingNames: [
          for (final m in methods)
            if (m.id != existing?.id) m.name,
        ],
      ),
    );
    if (result != null) {
      await ref.read(paymentMethodsProvider.notifier).save(result);
    }
  }

  Future<bool> _confirmDelete(
      BuildContext context, WidgetRef ref, PaymentMethod m) async {
    final ok = await showDeleteDialog(
      context,
      lead: Text('「${m.name}」を削除します。'),
      tailNote: 'この支払い方法を設定していたサブスクは「未設定」になります'
          '（サブスク自体は削除されません）。',
    );
    if (ok) {
      await ref.read(paymentMethodsProvider.notifier).delete(m.id);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? const [];
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: '支払い方法設定',
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
                  if (!isPremium)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '無料版：${methods.length}/${PremiumLimits.maxPaymentMethods} 件',
                        style: AppType.body(12, color: AppColors.textMuted),
                      ),
                    ),
                  for (final m in methods) ...[
                    SwipeToDelete(
                      id: m.id,
                      canDelete: !m.isBuiltIn,
                      onDelete: () => _confirmDelete(context, ref, m),
                      child: SoftCard(
                        onTap: () => _edit(context, ref, existing: m),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: m.color.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(m.iconData, color: m.color),
                            ),
                            const Gap(AppSpacing.md),
                            Expanded(
                                child: Text(m.name, style: AppType.body(15.5))),
                            if (m.isBuiltIn)
                              const Icon(Icons.lock_outline_rounded,
                                  size: 18, color: AppColors.textMuted)
                            else
                              Pressable(
                                onTap: () => _confirmDelete(context, ref, m),
                                child: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.md),
                  ],
                  SoftButton(
                    label: '支払い方法を追加',
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

class PaymentMethodEditorDialog extends StatefulWidget {
  const PaymentMethodEditorDialog({
    super.key,
    this.existing,
    required this.index,
    this.existingNames = const [],
    this.nameEditable = true,
  });
  final PaymentMethod? existing;
  final int index;

  /// Names of the other payment methods, used to block duplicates.
  final List<String> existingNames;

  /// Built-in methods keep their name fixed (icon/color still editable).
  final bool nameEditable;

  @override
  State<PaymentMethodEditorDialog> createState() => _PaymentMethodEditorDialogState();
}

class _PaymentMethodEditorDialogState extends State<PaymentMethodEditorDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  String? _error;
  late int _icon = widget.existing?.icon ?? _icons.first.codePoint;
  late int _color =
      widget.existing?.colorValue ?? AppAccent.of(context).deep.value;

  static const _icons = IconRegistry.paymentIcons;

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
      title: Text(widget.existing == null ? '支払い方法を追加' : '支払い方法を編集',
          style: AppType.display(19)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            enabled: widget.nameEditable,
            decoration: InputDecoration(
              labelText: '名前',
              errorText: _error,
              helperText:
                  widget.nameEditable ? null : '既定の支払い方法名は変更できません',
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
          const SectionHeader('アイコンカラー'),
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
              PaymentMethod(
                id: widget.existing?.id ?? const Uuid().v4(),
                name: name,
                icon: _icon,
                sortOrder: widget.existing?.sortOrder ?? widget.index,
                colorValue: _color,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
