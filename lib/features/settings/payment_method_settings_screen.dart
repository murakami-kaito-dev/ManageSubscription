import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/premium_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
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
      builder: (_) => _MethodDialog(existing: existing, index: methods.length),
    );
    if (result != null) {
      await ref.read(paymentMethodsProvider.notifier).save(result);
    }
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
                        '無料版：${methods.length}/${PremiumLimits.maxPaymentMethods} 件',
                        style: AppType.body(12, color: AppColors.textMuted),
                      ),
                    ),
                  for (final m in methods) ...[
                    SoftCard(
                      onTap: () => _edit(context, ref, existing: m),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(m.iconData,
                                color: AppColors.primaryDeep),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                              child: Text(m.name, style: AppType.body(15.5))),
                          Pressable(
                            onTap: () => ref
                                .read(paymentMethodsProvider.notifier)
                                .delete(m.id),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.textMuted),
                          ),
                        ],
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

class _MethodDialog extends StatefulWidget {
  const _MethodDialog({this.existing, required this.index});
  final PaymentMethod? existing;
  final int index;

  @override
  State<_MethodDialog> createState() => _MethodDialogState();
}

class _MethodDialogState extends State<_MethodDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late int _icon = widget.existing?.icon ?? _icons.first.codePoint;

  static const _icons = [
    Icons.credit_card_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.account_balance_rounded,
    Icons.phone_iphone_rounded,
    Icons.paid_rounded,
    Icons.qr_code_rounded,
    Icons.savings_rounded,
    Icons.currency_yen_rounded,
  ];

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
            decoration: const InputDecoration(labelText: '名前'),
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
                          ? AppColors.primarySoft
                          : AppColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _icon == ic.codePoint
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(ic,
                        size: 20,
                        color: _icon == ic.codePoint
                            ? AppColors.primaryDeep
                            : AppColors.textSecondary),
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
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              PaymentMethod(
                id: widget.existing?.id ?? const Uuid().v4(),
                name: _name.text.trim(),
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
