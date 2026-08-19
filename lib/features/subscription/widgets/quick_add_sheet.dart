import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/amount_input.dart';
import '../../../core/utils/billing.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/preset_icons.dart';
import '../../../core/utils/text_input.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/soft_button.dart';
import '../../../data/models/notify_rule.dart';
import '../../../data/models/quick_add_catalog.dart';
import '../../../data/models/subscription.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/subscription_providers.dart';
import '../subscription_form_screen.dart';

/// 「＋」から開く**クイック追加**メニュー。
///
/// よく使われるサブスク（公式価格つき・`CatalogService` が配信）と固定費を
/// タイルで並べ、タップ→プラン（or 金額）を選ぶだけでアイテムが完成する。
/// 名前・通貨(JPY)・色・アイコン・通知（1日前/3日前の9:00）・開始日(今日)は
/// すべて自動設定。従来の手入力フォームへは下部の「手入力する」から。
Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    builder: (_) => const _QuickAddSheet(),
  );
}

class _QuickAddSheet extends ConsumerWidget {
  const _QuickAddSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogServiceProvider).catalog;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        // 「手入力する」はホームの「＋」のように**浮かせて**上寄りに置く。
        // Stack で本文の上に重ね、右下からやや持ち上げた位置に固定する。
        child: Stack(
          children: [
            Column(
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
                Text('かんたん追加', style: AppType.display(18)),
                const Gap(AppSpacing.md),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                    children: [
                      _tileGrid([
                        for (final s in catalog.services)
                          _TileData(
                            name: s.name,
                            icon: s.icon,
                            colorValue: s.colorValue,
                            onTap: () => _openConfirm(context, service: s),
                          ),
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: AppSpacing.lg, bottom: AppSpacing.sm),
                        child: Text('固定費',
                            style: AppType.body(12,
                                weight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                      ),
                      _tileGrid([
                        for (final f in catalog.fixedCosts)
                          _TileData(
                            name: f.name,
                            icon: f.icon,
                            colorValue: f.colorValue,
                            onTap: () => _openConfirm(context, fixedCost: f),
                          ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            // 浮かせた手入力ボタン（ホームの「＋」相当の位置＝右下やや上）。
            Positioned(
              right: AppSpacing.lg,
              bottom: MediaQuery.sizeOf(context).height * 0.16,
              child: _ManualEntryFab(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SubscriptionFormScreen(),
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileGrid(List<_TileData> tiles) => GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.72,
        children: [for (final t in tiles) _Tile(data: t)],
      );

  void _openConfirm(BuildContext context,
      {QuickAddService? service, QuickAddFixedCost? fixedCost}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      builder: (_) =>
          _QuickAddConfirmSheet(service: service, fixedCost: fixedCost),
    );
  }
}

/// 「手入力する」の浮きボタン（ピル型）。ホームの「＋」と同じ
/// アクセントグラデ＋glow で、シート右下やや上に固定表示する。
class _ManualEntryFab extends StatelessWidget {
  const _ManualEntryFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppAccent.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.primary, accent.deep],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppShadows.accentGlow(accent.primary, intensity: 1.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: AppColors.onPrimary, size: 20),
            const Gap(AppSpacing.sm),
            Text('手入力する',
                style: AppType.body(14,
                    weight: FontWeight.w800, color: AppColors.onPrimary)),
          ],
        ),
      ),
    );
  }
}

class _TileData {
  const _TileData({
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.onTap,
  });
  final String name;
  final String icon;
  final int colorValue;
  final VoidCallback onTap;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.data});
  final _TileData data;

  @override
  Widget build(BuildContext context) {
    final asset = PresetIcons.assetOf(PresetIcons.keyFor(data.icon));
    return Pressable(
      onTap: data.onTap,
      scale: 0.92,
      child: Column(
        children: [
          if (asset != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SvgPicture.asset(asset, width: 52, height: 52),
            )
          else
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(data.colorValue),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                data.name.characters.first,
                style: AppType.display(20, color: AppColors.onPrimary),
              ),
            ),
          const Gap(4),
          Text(
            data.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppType.body(10, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// タイルをタップした後の確認シート:
/// サブスク → プランを選ぶ / 固定費 → 金額を入れる、＋開始日（今日・変更可）。
class _QuickAddConfirmSheet extends ConsumerStatefulWidget {
  const _QuickAddConfirmSheet({this.service, this.fixedCost})
      : assert(service != null || fixedCost != null);

  final QuickAddService? service;
  final QuickAddFixedCost? fixedCost;

  @override
  ConsumerState<_QuickAddConfirmSheet> createState() =>
      _QuickAddConfirmSheetState();
}

class _QuickAddConfirmSheetState extends ConsumerState<_QuickAddConfirmSheet> {
  int _planIndex = 0;
  DateTime _firstPayment = DateTime.now();
  final _amount = TextEditingController();
  bool _saving = false;

  bool get _isFixed => widget.fixedCost != null;
  String get _name => widget.service?.name ?? widget.fixedCost!.name;
  String get _icon => widget.service?.icon ?? widget.fixedCost!.icon;
  int get _colorValue =>
      widget.service?.colorValue ?? widget.fixedCost!.colorValue;

  double get _amountValue => _isFixed
      ? (double.tryParse(_amount.text.replaceAll(',', '').trim()) ?? 0)
      : widget.service!.plans[_planIndex].amount;

  bool get _canAdd => _amountValue > 0;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstPayment,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      locale: const Locale('ja'),
    );
    if (picked != null && mounted) setState(() => _firstPayment = picked);
  }

  Future<void> _add() async {
    if (!_canAdd || _saving) return;
    setState(() => _saving = true);
    final cycle =
        _isFixed ? BillingCycle.monthly : widget.service!.plans[_planIndex].cycle;
    final sub = Subscription(
      id: const Uuid().v4(),
      name: _name,
      amount: _amountValue,
      // カタログ価格は日本の公式価格（円）なので通貨は JPY で保存する。
      // 一覧の表示は既存の仕組みでメイン通貨に換算される。
      currencyCode: 'JPY',
      cycle: cycle,
      firstPaymentDate: _firstPayment,
      colorValue: _colorValue,
      imagePath: _icon.isEmpty ? null : PresetIcons.keyFor(_icon),
      usageCount: 0,
      notifyRules: const [
        NotifyRule(daysBefore: 1, hour: 9, minute: 0),
        NotifyRule(daysBefore: 3, hour: 9, minute: 0),
      ],
      sortOrder: ref.read(subscriptionCountProvider),
      createdAt: DateTime.now(),
    );
    await ref.read(subscriptionsProvider.notifier).save(sub);
    if (!mounted) return;
    Navigator.of(context)
      ..pop() // 確認シート
      ..pop(); // クイック追加シート
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_name を追加しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fmt = CurrencyFormatter(AppCurrency.jpy);
    final asset = PresetIcons.assetOf(PresetIcons.keyFor(_icon));

    return Padding(
      // キーボード（固定費の金額入力）で隠れないように持ち上げる。
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Gap(AppSpacing.lg),
              Row(
                children: [
                  if (asset != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SvgPicture.asset(asset, width: 40, height: 40),
                    ),
                  const Gap(AppSpacing.md),
                  Expanded(child: Text(_name, style: AppType.display(20))),
                ],
              ),
              const Gap(AppSpacing.lg),
              if (_isFixed) ...[
                Text('毎月の金額',
                    style: AppType.body(12,
                        weight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const Gap(AppSpacing.xs),
                TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [ThousandsSeparatorInputFormatter()],
                  contextMenuBuilder: noCameraScanContextMenu,
                  onChanged: (_) => setState(() {}),
                  style: AppType.display(18),
                  decoration: InputDecoration(
                    prefixText: '¥ ',
                    hintText: '例：80,000',
                    filled: true,
                    fillColor: AppColors.surfaceSunken,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ] else ...[
                Text('プランを選ぶ',
                    style: AppType.body(12,
                        weight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const Gap(AppSpacing.xs),
                for (var i = 0; i < widget.service!.plans.length; i++)
                  _planRow(i, widget.service!.plans[i], fmt),
              ],
              const Gap(AppSpacing.md),
              Pressable(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSunken,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_rounded,
                          size: 20, color: AppAccent.of(context).deep),
                      const Gap(AppSpacing.sm),
                      Text('初回支払日', style: AppType.body(13.5)),
                      const Spacer(),
                      Text(DateFormat('yyyy年M月d日').format(_firstPayment),
                          style:
                              AppType.body(13.5, weight: FontWeight.w700)),
                      const Gap(4),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const Gap(AppSpacing.sm),
              Text(
                '支払日の1日前・3日前の 9:00 に通知します（追加後に変更できます）',
                style: AppType.body(11.5, color: AppColors.textMuted),
              ),
              const Gap(AppSpacing.lg),
              SoftButton(
                label: _saving ? '追加中…' : '追加する',
                icon: Icons.check_rounded,
                onPressed: _canAdd && !_saving ? _add : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planRow(int i, QuickAddPlan plan, CurrencyFormatter fmt) {
    final selected = i == _planIndex;
    final accent = AppAccent.of(context);
    return Pressable(
      onTap: () => setState(() => _planIndex = i),
      scale: 0.985,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? accent.soft : AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? accent.deep : AppColors.textMuted,
            ),
            const Gap(AppSpacing.sm),
            Expanded(
                child: Text(plan.label,
                    style: AppType.body(13.5,
                        weight:
                            selected ? FontWeight.w700 : FontWeight.w500))),
            Text(
              '${fmt.format(plan.amount)} /${plan.cycle == BillingCycle.yearly ? '年' : '月'}',
              style: AppType.body(13.5, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
