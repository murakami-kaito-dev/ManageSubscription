import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/premium_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/billing.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/premium_crown.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../data/models/category.dart';
import '../../data/models/notify_rule.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/subscription.dart';
import '../../providers/premium_provider.dart';
import '../../providers/subscription_providers.dart';
import '../premium/premium_screen.dart';
import '../settings/category_settings_screen.dart';
import '../settings/payment_method_settings_screen.dart';
import 'widgets/cospa_preview.dart';

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({super.key, this.existing});
  final Subscription? existing;

  @override
  ConsumerState<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState
    extends ConsumerState<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _emoji;
  late final TextEditingController _usage;
  late final TextEditingController _usageUnit;
  late final TextEditingController _memo;

  late AppCurrency _currency;
  late BillingCycle _cycle;
  late DateTime _firstPayment;
  late int _colorValue;
  String? _categoryId;
  String? _paymentMethodId;
  late List<NotifyRule> _notifyRules;
  late bool _isPaused;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _amount = TextEditingController(
        text: e != null ? _trimAmount(e.amount) : '');
    _emoji = TextEditingController(text: e?.emoji ?? '');
    _usage = TextEditingController(
        text: e != null && e.usageCount > 0 ? _trimAmount(e.usageCount) : '');
    _usageUnit = TextEditingController(text: e?.usageUnit ?? '回');
    _memo = TextEditingController(text: e?.memo ?? '');
    _currency = e?.currency ?? AppCurrency.jpy;
    _cycle = e?.cycle ?? BillingCycle.monthly;
    _firstPayment = e?.firstPaymentDate ?? DateTime.now();
    _colorValue = e?.colorValue ?? AppColors.chartPalette.first.value;
    _categoryId = e?.categoryId;
    _paymentMethodId = e?.paymentMethodId;
    _notifyRules = [...?e?.notifyRules];
    _isPaused = e?.isPaused ?? false;
  }

  String _trimAmount(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    for (final c in [_name, _amount, _emoji, _usage, _usageUnit, _memo]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _amountValue => double.tryParse(_amount.text.trim()) ?? 0;
  double get _usageValue => double.tryParse(_usage.text.trim()) ?? 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstPayment,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _firstPayment = picked);
  }

  Future<void> _addCategory(int currentCount) async {
    final isPremium = ref.read(premiumProvider);
    if (!PremiumLimits.canAddCategory(isPremium, currentCount)) {
      PremiumScreen.show(context,
          reason: '無料版のカテゴリーは${PremiumLimits.maxCategories}件までです。');
      return;
    }
    final result = await showDialog<Category>(
      context: context,
      builder: (_) => CategoryEditorDialog(index: currentCount),
    );
    if (result == null) return;
    await ref.read(categoriesProvider.notifier).save(result);
    if (mounted) setState(() => _categoryId = result.id);
  }

  Future<void> _addPaymentMethod(int currentCount) async {
    final isPremium = ref.read(premiumProvider);
    if (!PremiumLimits.canAddPaymentMethod(isPremium, currentCount)) {
      PremiumScreen.show(context,
          reason: '無料版の支払い方法は${PremiumLimits.maxPaymentMethods}件までです。');
      return;
    }
    final result = await showDialog<PaymentMethod>(
      context: context,
      builder: (_) => PaymentMethodEditorDialog(index: currentCount),
    );
    if (result == null) return;
    await ref.read(paymentMethodsProvider.notifier).save(result);
    if (mounted) setState(() => _paymentMethodId = result.id);
  }

  Future<void> _addNotifyRule() async {
    final rule = await showDialog<NotifyRule>(
      context: context,
      builder: (_) => const _NotifyRuleDialog(),
    );
    if (rule != null) setState(() => _notifyRules.add(rule));
  }

  Future<void> _editNotifyRule(int index) async {
    final rule = await showDialog<NotifyRule>(
      context: context,
      builder: (_) => _NotifyRuleDialog(initial: _notifyRules[index]),
    );
    if (rule != null) setState(() => _notifyRules[index] = rule);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.existing?.id ?? const Uuid().v4();
    final count = ref.read(subscriptionCountProvider);
    final sub = Subscription(
      id: id,
      name: _name.text.trim(),
      amount: _amountValue,
      currencyCode: _currency.code,
      cycle: _cycle,
      firstPaymentDate: _firstPayment,
      colorValue: _colorValue,
      emoji: _emoji.text.trim().isEmpty ? null : _emoji.text.trim(),
      categoryId: _categoryId,
      paymentMethodId: _paymentMethodId,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      usageCount: _usageValue,
      usageUnit:
          _usageUnit.text.trim().isEmpty ? '回' : _usageUnit.text.trim(),
      isPaused: _isPaused,
      imagePath: widget.existing?.imagePath,
      notifyRules: _notifyRules,
      sortOrder: widget.existing?.sortOrder ?? count,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await ref.read(subscriptionsProvider.notifier).save(sub);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text(
          '「${widget.existing!.name}」を削除します。\n\n'
          '・ホーム一覧から消え、今月の合計・分析・カレンダー・支払い履歴の集計対象から外れます。\n'
          '・設定した支払い日や通知も削除されます。\n'
          '・カテゴリーや支払い方法そのものは削除されません。\n\n'
          'データは端末内にのみ保存されているため、削除すると元に戻せません。',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(subscriptionsProvider.notifier).delete(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? const [];

    return Scaffold(
      // Tap anywhere outside a text field to dismiss the keyboard.
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftHeader(
              title: _isEdit ? '編集' : '新規追加',
              trailing: SoftIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, 120),
                  children: [
                    _fieldCard(
                      child: TextFormField(
                        controller: _name,
                        decoration: _dec('サービス名', hint: '例：Netflix'),
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    _fieldCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _amount,
                              decoration: _dec('金額'),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                              ],
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  _amountValue < 0 ? '正しい金額を入力してください' : null,
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<AppCurrency>(
                              value: _currency,
                              decoration: _dec('通貨'),
                              items: [
                                for (final c in AppCurrency.values)
                                  DropdownMenuItem(
                                      value: c,
                                      child: Text('${c.symbol} ${c.code}')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _currency = v ?? _currency),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader('支払いサイクル'),
                    _CycleSelector(
                      value: _cycle,
                      onChanged: (c) => setState(() => _cycle = c),
                    ),
                    const Gap(AppSpacing.md),
                    _fieldCard(
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          const Icon(Icons.event_rounded,
                              color: AppColors.primaryDeep),
                          const Gap(AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('初回（次回）支払日',
                                    style: AppType.body(12,
                                        color: AppColors.textSecondary)),
                                const Gap(2),
                                Text(
                                    DateFormat('yyyy年M月d日')
                                        .format(_firstPayment),
                                    style: AppType.body(16,
                                        weight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    const SectionHeader('アイコン'),
                    _fieldCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: _emoji,
                              decoration:
                                  _dec('絵文字', hint: '🎬'),
                              maxLength: 2,
                              buildCounter: (_,
                                      {required currentLength,
                                      required isFocused,
                                      maxLength}) =>
                                  null,
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          _ColorPicker(
                            selected: _colorValue,
                            onSelected: (v) => setState(() => _colorValue = v),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader('カテゴリー'),
                    _ChipPicker(
                      items: [
                        for (final c in categories) (id: c.id, label: c.name),
                      ],
                      selectedId: _categoryId,
                      onSelected: (id) => setState(() => _categoryId = id),
                      onAdd: () => _addCategory(categories.length),
                    ),
                    const SectionHeader('支払い方法'),
                    _ChipPicker(
                      items: [
                        for (final m in methods) (id: m.id, label: m.name),
                      ],
                      selectedId: _paymentMethodId,
                      onSelected: (id) =>
                          setState(() => _paymentMethodId = id),
                      onAdd: () => _addPaymentMethod(methods.length),
                    ),
                    SectionHeader('コスパチェッカー',
                        trailing: Text('1回あたりの単価を自動計算',
                            style: AppType.body(11,
                                color: AppColors.textMuted))),
                    _fieldCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _usage,
                                  decoration:
                                      _dec('月の推定利用回数', hint: '例：8'),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]')),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const Gap(AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _usageUnit,
                                  decoration: _dec('単位'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const Gap(AppSpacing.md),
                          CospaPreview(
                            monthlyAmount: _amountValue * _cycle.monthlyFactor,
                            currency: _currency,
                            usage: _usageValue,
                            unit: _usageUnit.text.trim().isEmpty
                                ? '回'
                                : _usageUnit.text.trim(),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader('支払い日前の通知'),
                    _NotifyRulesEditor(
                      rules: _notifyRules,
                      limit: PremiumLimits.notifyRuleLimit(isPremium),
                      onAdd: _addNotifyRule,
                      onEdit: _editNotifyRule,
                      onRemove: (i) =>
                          setState(() => _notifyRules.removeAt(i)),
                      onNeedPremium: () => PremiumScreen.show(context,
                          reason:
                              '無料版で設定できる通知は${PremiumLimits.maxNotifyRules}件までです。'),
                    ),
                    const SectionHeader('画像', premium: true),
                    _ImageRow(
                      isPremium: isPremium,
                      onNeedPremium: () => PremiumScreen.show(context,
                          reason: '画像の登録はプレミアム機能です。'),
                    ),
                    const SectionHeader('メモ'),
                    _fieldCard(
                      child: TextFormField(
                        controller: _memo,
                        decoration: _dec('メモ', hint: '任意'),
                        maxLines: 3,
                      ),
                    ),
                    if (_isEdit) ...[
                      const SectionHeader('状態'),
                      _fieldCard(
                        child: Row(
                          children: [
                            Expanded(
                                child: Text('このサブスクを停止中にする',
                                    style: AppType.body(15))),
                            Switch(
                              value: _isPaused,
                              onChanged: (v) => setState(() => _isPaused = v),
                            ),
                          ],
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      SoftButton(
                        label: 'このサブスクを削除',
                        icon: Icons.delete_outline_rounded,
                        kind: SoftButtonKind.neutral,
                        onPressed: _delete,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _SaveBar(onSave: _save, label: _isEdit ? '保存する' : '追加する'),
          ],
        ),
      ),
      ),
    );
  }

  Widget _fieldCard({required Widget child, VoidCallback? onTap}) => SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: child,
      );

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: InputBorder.none,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: AppType.body(13, color: AppColors.textSecondary),
        hintStyle: AppType.body(15, color: AppColors.textMuted),
      );
}

class _CycleSelector extends StatelessWidget {
  const _CycleSelector({required this.value, required this.onChanged});
  final BillingCycle value;
  final ValueChanged<BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    const cycles = [
      (BillingCycle.monthly, '月額'),
      (BillingCycle.yearly, '年額'),
      (BillingCycle.weekly, '週額'),
    ];
    return SoftCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (final c in cycles)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(c.$1),
                scale: 0.96,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == c.$1
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(c.$2,
                      style: AppType.body(14,
                          weight: FontWeight.w700,
                          color: value == c.$1
                              ? AppColors.onPrimary
                              : AppColors.textSecondary)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in AppColors.chartPalette)
          Pressable(
            onTap: () => onSelected(c.value),
            scale: 0.85,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.value == selected
                      ? AppColors.textPrimary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: c.value == selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _ChipPicker extends StatelessWidget {
  const _ChipPicker({
    required this.items,
    required this.selectedId,
    required this.onSelected,
    this.onAdd,
  });
  final List<({String id, String label})> items;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  /// When provided, a "+" chip is appended that creates a new entry inline.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final it in items)
          _chip(it.label, selectedId == it.id,
              () => onSelected(selectedId == it.id ? null : it.id)),
        if (onAdd != null) _addChip(onAdd!),
      ],
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => Pressable(
        onTap: onTap,
        scale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: sel ? null : AppShadows.soft(),
          ),
          child: Text(label,
              style: AppType.body(13.5,
                  weight: FontWeight.w600,
                  color: sel ? AppColors.onPrimary : AppColors.textPrimary)),
        ),
      );

  /// A compact circular "+" the same height as the chips.
  Widget _addChip(VoidCallback onTap) => Pressable(
        onTap: onTap,
        scale: 0.9,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft(),
          ),
          child: const Icon(Icons.add_rounded,
              color: AppColors.primaryDeep, size: 22),
        ),
      );
}

/// Lists "N days before at HH:MM" reminder rules with add/edit/remove, like a
/// calendar app. The add button respects the free-tier limit.
class _NotifyRulesEditor extends StatelessWidget {
  const _NotifyRulesEditor({
    required this.rules,
    required this.limit,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onNeedPremium,
  });
  final List<NotifyRule> rules;
  final int limit;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;
  final VoidCallback onNeedPremium;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (var i = 0; i < rules.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      size: 20, color: AppColors.primaryDeep),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Pressable(
                      onTap: () => onEdit(i),
                      scale: 0.98,
                      child: Row(
                        children: [
                          Text(rules[i].dayLabel,
                              style: AppType.body(15, weight: FontWeight.w700)),
                          const Gap(AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSunken,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(rules[i].timeLabel,
                                style: AppType.body(13,
                                    weight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: () => onRemove(i),
                    child: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('通知は設定されていません',
                  style: AppType.body(13, color: AppColors.textMuted)),
            ),
          const Gap(AppSpacing.xs),
          Pressable(
            onTap: rules.length >= limit ? onNeedPremium : onAdd,
            scale: 0.98,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded,
                      size: 18, color: AppColors.primaryDeep),
                  const Gap(6),
                  Text('通知を追加',
                      style: AppType.body(14,
                          weight: FontWeight.w700,
                          color: AppColors.primaryDeep)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to choose "how many days before" and "at what time".
class _NotifyRuleDialog extends StatefulWidget {
  const _NotifyRuleDialog({this.initial});
  final NotifyRule? initial;

  @override
  State<_NotifyRuleDialog> createState() => _NotifyRuleDialogState();
}

class _NotifyRuleDialogState extends State<_NotifyRuleDialog> {
  late int _days = widget.initial?.daysBefore ?? 1;
  late TimeOfDay _time =
      widget.initial?.time ?? const TimeOfDay(hour: 9, minute: 0);

  static const _dayOptions = [0, 1, 2, 3, 5, 7, 14, 30];

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
      title: Text('通知のタイミング', style: AppType.display(19)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('支払い日の何日前'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _dayOptions)
                  Pressable(
                    scale: 0.94,
                    onTap: () => setState(() => _days = d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _days == d
                            ? AppColors.primary
                            : AppColors.surfaceSunken,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(d == 0 ? '当日' : '$d日前',
                          style: AppType.body(13.5,
                              weight: FontWeight.w600,
                              color: _days == d
                                  ? AppColors.onPrimary
                                  : AppColors.textPrimary)),
                    ),
                  ),
              ],
            ),
            const SectionHeader('通知する時刻'),
            Pressable(
              onTap: _pickTime,
              scale: 0.98,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: AppColors.primaryDeep),
                    const Gap(AppSpacing.md),
                    Text(
                      _time.format(context),
                      style: AppType.display(18),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル')),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            NotifyRule(
                daysBefore: _days, hour: _time.hour, minute: _time.minute),
          ),
          child: const Text('決定'),
        ),
      ],
    );
  }
}

class _ImageRow extends StatelessWidget {
  const _ImageRow({required this.isPremium, required this.onNeedPremium});
  final bool isPremium;
  final VoidCallback onNeedPremium;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: isPremium ? () {} : onNeedPremium,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.image_rounded,
                color: AppColors.primaryDeep),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Text(
              isPremium ? '画像を選択して登録' : '画像の登録（プレミアム）',
              style: AppType.body(15),
            ),
          ),
          if (!isPremium) const PremiumCrown(),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onSave, required this.label});
  final VoidCallback onSave;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
          AppSpacing.md + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: AppColors.canvas),
      child: SoftButton(label: label, icon: Icons.check_rounded, onPressed: onSave),
    );
  }
}
