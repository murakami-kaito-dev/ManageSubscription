import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/premium_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/delete_dialog.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/billing.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_header.dart';
import '../../data/models/category.dart';
import '../../data/models/notify_rule.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/subscription.dart';
import '../../providers/core_providers.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
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
  late int _intervalCount;
  late IntervalUnit _intervalUnit;
  late DateTime _firstPayment;
  late int _colorValue;
  String? _categoryId;
  String? _paymentMethodId;
  String? _imagePath;
  bool _pickingImage = false;
  late List<NotifyRule> _notifyRules;
  late bool _isPaused;
  late bool _detailsExpanded;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _amount =
        TextEditingController(text: e != null ? _trimAmount(e.amount) : '');
    _emoji = TextEditingController(text: e?.emoji ?? '');
    _usage = TextEditingController(
        text: e != null && e.usageCount > 0 ? _trimAmount(e.usageCount) : '');
    _usageUnit = TextEditingController(text: e?.usageUnit ?? '回');
    _memo = TextEditingController(text: e?.memo ?? '');
    _currency = e?.currency ?? AppCurrency.jpy;
    _cycle = e?.cycle ?? BillingCycle.monthly;
    _intervalCount = e?.intervalCount ?? 1;
    _intervalUnit = e?.intervalUnit ?? IntervalUnit.month;
    _firstPayment = e?.firstPaymentDate ?? DateTime.now();
    _colorValue = e?.colorValue ?? AppColors.chartPalette.first.value;
    _categoryId = e?.categoryId;
    _paymentMethodId = e?.paymentMethodId;
    _imagePath = e?.imagePath;
    _notifyRules = [...?e?.notifyRules];
    _isPaused = e?.isPaused ?? false;
    // Details start expanded only when the user opted into "常に表示".
    _detailsExpanded = ref.read(settingsProvider).alwaysShowDetails;
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

  Recurrence get _recurrence => switch (_cycle) {
        BillingCycle.monthly => const Recurrence(1, IntervalUnit.month),
        BillingCycle.yearly => const Recurrence(12, IntervalUnit.month),
        BillingCycle.weekly => const Recurrence(1, IntervalUnit.week),
        BillingCycle.custom => Recurrence(_intervalCount, _intervalUnit),
      };

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
    final existing = ref.read(categoriesProvider).valueOrNull ?? const [];
    final result = await showDialog<Category>(
      context: context,
      builder: (_) => CategoryEditorDialog(
        index: currentCount,
        existingNames: [for (final c in existing) c.name],
      ),
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
    final existing = ref.read(paymentMethodsProvider).valueOrNull ?? const [];
    final result = await showDialog<PaymentMethod>(
      context: context,
      builder: (_) => PaymentMethodEditorDialog(
        index: currentCount,
        existingNames: [for (final m in existing) m.name],
      ),
    );
    if (result == null) return;
    await ref.read(paymentMethodsProvider.notifier).save(result);
    if (mounted) setState(() => _paymentMethodId = result.id);
  }

  Future<void> _editCategory(Category c) async {
    final all = ref.read(categoriesProvider).valueOrNull ?? const [];
    final result = await showDialog<Category>(
      context: context,
      builder: (_) => CategoryEditorDialog(
        existing: c,
        index: c.sortOrder,
        nameEditable: !c.isBuiltIn,
        existingNames: [
          for (final x in all)
            if (x.id != c.id) x.name
        ],
      ),
    );
    if (result != null) {
      await ref.read(categoriesProvider.notifier).save(result);
    }
  }

  Future<void> _deleteCategory(Category c) async {
    final ok = await showDeleteDialog(
      context,
      lead: Text('「${c.name}」を削除します。'),
      tailNote: 'このカテゴリーを設定していたサブスクは「未設定」になります'
          '（サブスク自体は削除されません）。',
    );
    if (ok) {
      if (_categoryId == c.id) setState(() => _categoryId = null);
      await ref.read(categoriesProvider.notifier).delete(c.id);
    }
  }

  Future<void> _editPaymentMethod(PaymentMethod m) async {
    final all = ref.read(paymentMethodsProvider).valueOrNull ?? const [];
    final result = await showDialog<PaymentMethod>(
      context: context,
      builder: (_) => PaymentMethodEditorDialog(
        existing: m,
        index: m.sortOrder,
        nameEditable: !m.isBuiltIn,
        existingNames: [
          for (final x in all)
            if (x.id != m.id) x.name
        ],
      ),
    );
    if (result != null) {
      await ref.read(paymentMethodsProvider.notifier).save(result);
    }
  }

  Future<void> _deletePaymentMethod(PaymentMethod m) async {
    final ok = await showDeleteDialog(
      context,
      lead: Text('「${m.name}」を削除します。'),
      tailNote: 'この支払い方法を設定していたサブスクは「未設定」になります'
          '（サブスク自体は削除されません）。',
    );
    if (ok) {
      if (_paymentMethodId == m.id) setState(() => _paymentMethodId = null);
      await ref.read(paymentMethodsProvider.notifier).delete(m.id);
    }
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

  Future<void> _pickImage({required bool fromCamera}) async {
    if (!ref.read(premiumProvider)) {
      PremiumScreen.show(context, reason: '画像の登録はプレミアム機能です。');
      return;
    }
    setState(() => _pickingImage = true);
    try {
      final path = await ref
          .read(imagePickerServiceProvider)
          .pickAndCropSquare(fromCamera: fromCamera);
      if (path != null && mounted) setState(() => _imagePath = path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像を読み込めませんでした')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _chooseImageSource() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.canvas,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(AppSpacing.md),
            ListTile(
              leading: Icon(Icons.photo_library_rounded,
                  color: AppAccent.of(context).deep),
              title: const Text('写真から選ぶ'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(fromCamera: false);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_rounded,
                  color: AppAccent.of(context).deep),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(fromCamera: true);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
                title: const Text('画像を削除'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagePath = null);
                },
              ),
            const Gap(AppSpacing.md),
          ],
        ),
      ),
    );
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
      intervalCount: _intervalCount,
      intervalUnit: _intervalUnit,
      firstPaymentDate: _firstPayment,
      colorValue: _colorValue,
      emoji: _emoji.text.trim().isEmpty ? null : _emoji.text.trim(),
      categoryId: _categoryId,
      paymentMethodId: _paymentMethodId,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      usageCount: _usageValue,
      usageUnit: _usageUnit.text.trim().isEmpty ? '回' : _usageUnit.text.trim(),
      isPaused: _isPaused,
      imagePath: _imagePath,
      notifyRules: _notifyRules,
      sortOrder: widget.existing?.sortOrder ?? count,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await ref.read(subscriptionsProvider.notifier).save(sub);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDeleteDialog(
      context,
      lead: RichText(
        text: TextSpan(
          style: AppType.body(14, height: 1.5),
          children: [
            const TextSpan(text: '一度削除すると'),
            TextSpan(
                text: '全ての記録',
                style: AppType.body(14,
                    weight: FontWeight.w800, height: 1.5)),
            const TextSpan(text: 'が削除されます。'),
          ],
        ),
      ),
    );
    if (ok) {
      await ref
          .read(subscriptionsProvider.notifier)
          .delete(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? const [];
    final alwaysShow = ref.watch(settingsProvider).alwaysShowDetails;

    // ── "詳細設定" content (icon / category / payment method / cospa) ──────────
    final iconSection = _fieldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconPreview(
                imagePath: _imagePath,
                emoji: _emoji.text.trim(),
                colorValue: _colorValue,
                name: _name.text.trim(),
                busy: _pickingImage,
                onTap: _chooseImageSource,
              ),
              const Gap(AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _imagePath != null
                          ? '画像を設定中'
                          : (_emoji.text.trim().isNotEmpty
                              ? '入力した文字を表示中'
                              : '未設定（※名前の頭文字を表示中）'),
                      style: AppType.body(13,
                          weight: FontWeight.w700,
                          color: _imagePath != null ||
                                  _emoji.text.trim().isNotEmpty
                              ? AppAccent.of(context).deep
                              : AppColors.textMuted),
                    ),
                    const Gap(AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniBtn(
                          icon: Icons.image_rounded,
                          label: '画像',
                          onTap: _chooseImageSource,
                        ),
                        if (_imagePath != null)
                          _MiniBtn(
                            icon: Icons.close_rounded,
                            label: '画像を消す',
                            onTap: () => setState(() => _imagePath = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          // Shown as the icon when no image is set — any one character.
          SizedBox(
            width: 160,
            child: TextFormField(
              controller: _emoji,
              enabled: _imagePath == null,
              onChanged: (_) => setState(() {}),
              decoration: _dec('表示する文字（1字）', hint: '例：N / 🎬'),
              maxLength: 2,
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text('背景の色', style: AppType.body(12, color: AppColors.textSecondary)),
          const Gap(AppSpacing.sm),
          _ColorPicker(
            selected: _colorValue,
            onSelected: (v) => setState(() => _colorValue = v),
          ),
        ],
      ),
    );

    final categorySection = _ChipPicker(
      items: [
        for (final c in categories)
          (id: c.id, label: c.name, icon: c.iconData, color: c.color),
      ],
      selectedId: _categoryId,
      onSelected: (id) => setState(() => _categoryId = id),
      onAdd: () => _addCategory(categories.length),
      onEdit: (id) => _editCategory(categories.firstWhere((c) => c.id == id)),
      onDelete: (id) =>
          _deleteCategory(categories.firstWhere((c) => c.id == id)),
      canDelete: (id) => !categories.firstWhere((c) => c.id == id).isBuiltIn,
    );

    final paymentSection = _ChipPicker(
      items: [
        for (final m in methods)
          (id: m.id, label: m.name, icon: m.iconData, color: m.color),
      ],
      selectedId: _paymentMethodId,
      onSelected: (id) => setState(() => _paymentMethodId = id),
      onAdd: () => _addPaymentMethod(methods.length),
      onEdit: (id) => _editPaymentMethod(methods.firstWhere((m) => m.id == id)),
      onDelete: (id) =>
          _deletePaymentMethod(methods.firstWhere((m) => m.id == id)),
      canDelete: (id) => !methods.firstWhere((m) => m.id == id).isBuiltIn,
    );

    final cospaSection = _fieldCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _usage,
                  decoration: _dec('月の推定利用回数', hint: '例：8'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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
            monthlyAmount: _amountValue * _recurrence.monthlyFactor,
            currency: _currency,
            usage: _usageValue,
            unit: _usageUnit.text.trim().isEmpty ? '回' : _usageUnit.text.trim(),
          ),
        ],
      ),
    );

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
                      const SectionHeader('基本情報'),
                      _basicInfoCard(),
                      const SectionHeader('支払いサイクル・初回支払日'),
                      _cycleDateCard(),
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
                          kind: SoftButtonKind.danger,
                          onPressed: _delete,
                        ),
                      ],
                      // ── 詳細設定（デフォルトは折りたたみ）──────────────────────
                      const Gap(AppSpacing.lg),
                      _DetailsSection(
                        expanded: _detailsExpanded,
                        alwaysShow: alwaysShow,
                        onToggleExpand: () => setState(
                            () => _detailsExpanded = !_detailsExpanded),
                        onToggleAlways: (v) {
                          ref
                              .read(settingsProvider.notifier)
                              .setAlwaysShowDetails(v);
                          setState(() {
                            if (v) _detailsExpanded = true;
                          });
                        },
                        children: [
                          const SectionHeader('アイコン'),
                          iconSection,
                          const SectionHeader('カテゴリー'),
                          categorySection,
                          const SectionHeader('支払い方法'),
                          paymentSection,
                          SectionHeader('コスパチェッカー',
                              trailing: Text('1回あたりの単価を自動計算',
                                  style: AppType.body(11,
                                      color: AppColors.textMuted))),
                          cospaSection,
                        ],
                      ),
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

  Widget get _innerDivider =>
      Divider(height: 1, color: AppColors.textMuted.withOpacity(0.18));

  /// One card holding service name + amount + currency together.
  Widget _basicInfoCard() => _fieldCard(
        child: Column(
          children: [
            TextFormField(
              controller: _name,
              decoration: _dec('サービス名', hint: '例：Netflix'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
            ),
            _innerDivider,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amount,
                    decoration: _dec('金額'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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
                            value: c, child: Text('${c.symbol} ${c.code}')),
                    ],
                    onChanged: (v) =>
                        setState(() => _currency = v ?? _currency),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// One card holding the cycle selector (incl. custom) + first payment date.
  Widget _cycleDateCard() => _fieldCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(AppSpacing.xs),
            _CycleSelector(
              value: _cycle,
              onChanged: (c) => setState(() => _cycle = c),
            ),
            if (_cycle == BillingCycle.custom) ...[
              const Gap(AppSpacing.md),
              _CustomIntervalRow(
                count: _intervalCount,
                unit: _intervalUnit,
                onCountChanged: (v) =>
                    setState(() => _intervalCount = v.clamp(1, 999)),
                onUnitChanged: (u) => setState(() => _intervalUnit = u),
              ),
            ],
            const Gap(AppSpacing.sm),
            _innerDivider,
            Pressable(
              onTap: _pickDate,
              scale: 0.99,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded,
                        color: AppAccent.of(context).deep),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('初回支払日',
                              style: AppType.body(12,
                                  color: AppColors.textSecondary)),
                          const Gap(2),
                          Text(DateFormat('yyyy年M月d日').format(_firstPayment),
                              style: AppType.body(16, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      (BillingCycle.custom, 'カスタム'),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final c in cycles)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(c.$1),
                scale: 0.96,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        value == c.$1 ? AppAccent.of(context).primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(c.$2,
                      style: AppType.body(13.5,
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

/// Custom interval controls: "毎 [N] [日/週/ヶ月] ごと" with a live preview.
class _CustomIntervalRow extends StatelessWidget {
  const _CustomIntervalRow({
    required this.count,
    required this.unit,
    required this.onCountChanged,
    required this.onUnitChanged,
  });
  final int count;
  final IntervalUnit unit;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<IntervalUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('毎', style: AppType.body(14)),
            const Gap(AppSpacing.sm),
            _Stepper(value: count, onChanged: onCountChanged),
            const Gap(AppSpacing.md),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  for (final u in IntervalUnit.values)
                    Pressable(
                      scale: 0.94,
                      onTap: () => onUnitChanged(u),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color:
                              unit == u ? AppAccent.of(context).primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(u.shortLabel,
                            style: AppType.body(13.5,
                                weight: FontWeight.w700,
                                color: unit == u
                                    ? AppColors.onPrimary
                                    : AppColors.textPrimary)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.sm),
        Text('「$count${unit.everyLabel}」に支払われます',
            style: AppType.body(12.5, color: AppAccent.of(context).deep)),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback onTap) => Pressable(
          onTap: onTap,
          scale: 0.9,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppAccent.of(context).deep),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove_rounded, () => onChanged(value - 1)),
        Container(
          width: 34,
          alignment: Alignment.center,
          child: Text('$value',
              style: AppType.display(18, weight: FontWeight.w800)),
        ),
        btn(Icons.add_rounded, () => onChanged(value + 1)),
      ],
    );
  }
}

/// Collapsible "詳細設定" section holding the icon / category / payment method /
/// cospa controls. Collapsed by default; a "常に表示" switch (persisted) makes it
/// open automatically next time.
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.expanded,
    required this.alwaysShow,
    required this.onToggleExpand,
    required this.onToggleAlways,
    required this.children,
  });
  final bool expanded;
  final bool alwaysShow;
  final VoidCallback onToggleExpand;
  final ValueChanged<bool> onToggleAlways;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plain text header (like 状態 / メモ), tappable to expand.
        Pressable(
          onTap: onToggleExpand,
          scale: 0.99,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs, AppSpacing.lg, AppSpacing.xs, AppSpacing.sm),
            child: Row(
              children: [
                Text('詳細設定をする',
                    style: AppType.body(13,
                        weight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const Gap(6),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "常に表示" — a plain label + toggle, no card background.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('常に表示', style: AppType.body(15)),
                    ),
                    Switch(value: alwaysShow, onChanged: onToggleAlways),
                  ],
                ),
              ),
              ...children,
            ],
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
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
    this.onEdit,
    this.onDelete,
    this.canDelete,
  });
  final List<({String id, String label, IconData icon, Color color})> items;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  /// When provided, a "+" chip is appended that creates a new entry inline.
  final VoidCallback? onAdd;

  /// Long-press actions. Tap always selects; long-press opens a menu.
  final ValueChanged<String>? onEdit;
  final ValueChanged<String>? onDelete;
  final bool Function(String id)? canDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final it in items)
          _chip(context, it, selectedId == it.id,
              () => onSelected(selectedId == it.id ? null : it.id)),
        if (onAdd != null) _addChip(onAdd!),
      ],
    );
  }

  void _showMenu(BuildContext context,
      ({String id, String label, IconData icon, Color color}) it) {
    final deletable = canDelete?.call(it.id) ?? false;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.canvas,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(it.icon, size: 18, color: it.color),
                  const Gap(8),
                  Text(it.label, style: AppType.display(16)),
                ],
              ),
            ),
            if (onEdit != null)
              ListTile(
                leading: Icon(Icons.edit_rounded,
                    color: AppAccent.of(context).deep),
                title: const Text('編集する'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!(it.id);
                },
              ),
            if (onDelete != null && deletable)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
                title: const Text('削除する',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!(it.id);
                },
              ),
            if (onDelete != null && !deletable)
              const ListTile(
                leading: Icon(Icons.lock_outline_rounded,
                    color: AppColors.textMuted),
                title: Text('既定の項目は削除できません',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            const Gap(AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    ({String id, String label, IconData icon, Color color}) it,
    bool sel,
    VoidCallback onTap,
  ) =>
      Pressable(
        onTap: onTap,
        onLongPress: onEdit != null ? () => _showMenu(context, it) : null,
        scale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          decoration: BoxDecoration(
            color: sel ? AppAccent.of(context).primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: sel ? null : AppShadows.soft(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A color-tinted disc carrying the chosen icon, so the icon and
              // color the user picked are actually visible on the chip.
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.onPrimary.withOpacity(0.25)
                      : it.color.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(it.icon,
                    size: 15, color: sel ? AppColors.onPrimary : it.color),
              ),
              const Gap(8),
              Text(it.label,
                  style: AppType.body(13.5,
                      weight: FontWeight.w600,
                      color:
                          sel ? AppColors.onPrimary : AppColors.textPrimary)),
            ],
          ),
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
                  Icon(Icons.notifications_active_rounded,
                      size: 20, color: AppAccent.of(context).deep),
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
                color: AppAccent.of(context).soft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded,
                      size: 18, color: AppAccent.of(context).deep),
                  const Gap(6),
                  Text('通知を追加',
                      style: AppType.body(14,
                          weight: FontWeight.w700,
                          color: AppAccent.of(context).deep)),
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
  late int _hour = widget.initial?.hour ?? 9;
  late int _minute = widget.initial?.minute ?? 0;

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
            _DaysBeforeWheel(
              value: _days,
              onChanged: (d) => setState(() => _days = d),
            ),
            const SectionHeader('通知する時刻'),
            _WheelTimePicker(
              hour: _hour,
              minute: _minute,
              onChanged: (h, m) => setState(() {
                _hour = h;
                _minute = m;
              }),
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
            NotifyRule(daysBefore: _days, hour: _hour, minute: _minute),
          ),
          child: const Text('決定'),
        ),
      ],
    );
  }
}

/// A single vertical wheel to pick "how many days before" (0 = 当日).
class _DaysBeforeWheel extends StatefulWidget {
  const _DaysBeforeWheel({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_DaysBeforeWheel> createState() => _DaysBeforeWheelState();
}

class _DaysBeforeWheelState extends State<_DaysBeforeWheel> {
  static const _max = 60;
  late final FixedExtentScrollController _ctrl =
      FixedExtentScrollController(initialItem: widget.value.clamp(0, _max));
  late int _value = widget.value;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SizedBox(
        height: 130,
        child: Stack(
          children: [
            Center(
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppAccent.of(context).primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ListWheelScrollView.useDelegate(
              controller: _ctrl,
              itemExtent: 40,
              perspective: 0.004,
              diameterRatio: 1.3,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) {
                setState(() => _value = i);
                widget.onChanged(i);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _max + 1,
                builder: (context, i) {
                  final sel = i == _value;
                  return Center(
                    child: Text(
                      i == 0 ? '当日' : '$i日前',
                      style: AppType.display(sel ? 20 : 16,
                          color: sel
                              ? AppAccent.of(context).deep
                              : AppColors.textMuted),
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

/// A scrollable hour:minute picker (vertical number wheels) — familiar to
/// Japanese users and clearer than the analog clock dial.
class _WheelTimePicker extends StatefulWidget {
  const _WheelTimePicker({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  State<_WheelTimePicker> createState() => _WheelTimePickerState();
}

class _WheelTimePickerState extends State<_WheelTimePicker> {
  late final FixedExtentScrollController _hourCtrl =
      FixedExtentScrollController(initialItem: widget.hour);
  late final FixedExtentScrollController _minCtrl =
      FixedExtentScrollController(initialItem: widget.minute);
  late int _hour = widget.hour;
  late int _minute = widget.minute;

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            // Highlight band for the centered (selected) row.
            Center(
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppAccent.of(context).primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _wheel(
                    controller: _hourCtrl,
                    count: 24,
                    suffix: '時',
                    onSelected: (h) {
                      setState(() => _hour = h);
                      widget.onChanged(h, _minute);
                    },
                  ),
                ),
                Text(':',
                    style: AppType.display(22, color: AppColors.textMuted)),
                Expanded(
                  child: _wheel(
                    controller: _minCtrl,
                    count: 60,
                    suffix: '分',
                    onSelected: (m) {
                      setState(() => _minute = m);
                      widget.onChanged(_hour, m);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String suffix,
    required ValueChanged<int> onSelected,
  }) {
    final selected = suffix == '時' ? _hour : _minute;
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      perspective: 0.004,
      diameterRatio: 1.3,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, i) {
          final isSel = i == selected;
          return Center(
            child: Text(
              '${i.toString().padLeft(2, '0')}$suffix',
              style: AppType.display(isSel ? 22 : 18,
                  color: isSel ? AppAccent.of(context).deep : AppColors.textMuted),
            ),
          );
        },
      ),
    );
  }
}

/// A large, unambiguous preview of the subscription icon. Clearly shows which
/// of the three states is active: image, emoji, or unset (name initial).
class _IconPreview extends StatelessWidget {
  const _IconPreview({
    required this.imagePath,
    required this.emoji,
    required this.colorValue,
    required this.name,
    required this.busy,
    required this.onTap,
  });
  final String? imagePath;
  final String emoji;
  final int colorValue;
  final String name;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    final bool isSet = imagePath != null || emoji.isNotEmpty;

    Widget content;
    if (busy) {
      content = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (imagePath != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(File(imagePath!), fit: BoxFit.cover),
      );
    } else if (emoji.isNotEmpty) {
      content =
          Center(child: Text(emoji, style: const TextStyle(fontSize: 34)));
    } else {
      content = Center(
        child: Text(
          name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
          style: AppType.display(30, color: color),
        ),
      );
    }

    return Pressable(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: imagePath != null ? null : color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSet ? color.withOpacity(0.5) : AppColors.textMuted,
            width: isSet ? 2 : 1.5,
            style: isSet ? BorderStyle.solid : BorderStyle.solid,
          ),
          boxShadow: AppShadows.soft(),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: content),
            Positioned(
              right: 3,
              bottom: 3,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppAccent.of(context).primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded,
                    size: 11, color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppShadows.soft(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppAccent.of(context).deep),
            const Gap(5),
            Text(label, style: AppType.body(12.5, weight: FontWeight.w600)),
          ],
        ),
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
      child: SoftButton(
          label: label, icon: Icons.check_rounded, onPressed: onSave),
    );
  }
}
