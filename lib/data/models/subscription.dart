import 'package:flutter/material.dart';

import '../../core/utils/billing.dart';
import '../../core/utils/currency.dart';
import 'notify_rule.dart';

@immutable
class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.currencyCode,
    required this.cycle,
    required this.firstPaymentDate,
    required this.colorValue,
    this.emoji,
    this.categoryId,
    this.paymentMethodId,
    this.memo,
    this.usageCount = 0,
    this.usageUnit = '回',
    this.isPaused = false,
    this.imagePath,
    this.notifyRules = const [NotifyRule(daysBefore: 1)],
    this.sortOrder = 0,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double amount;
  final String currencyCode;
  final BillingCycle cycle;
  final DateTime firstPaymentDate;
  final int colorValue;
  final String? emoji;
  final String? categoryId;
  final String? paymentMethodId;
  final String? memo;

  /// "Cospa checker": estimated uses (or hours) per month.
  final double usageCount;
  final String usageUnit;

  final bool isPaused;
  final String? imagePath; // premium-only local image
  final List<NotifyRule> notifyRules; // "N days before at HH:MM" reminders
  final int sortOrder;
  final DateTime createdAt;

  Color get color => Color(colorValue);
  AppCurrency get currency => AppCurrencyX.fromCode(currencyCode);

  // ── Derived money ─────────────────────────────────────────────────────
  double get monthlyAmount => amount * cycle.monthlyFactor;
  double get yearlyAmount => amount * cycle.yearlyFactor;

  double monthlyAmountIn(AppCurrency target) =>
      CurrencyRates.convert(monthlyAmount, currencyCode, target.code);
  double yearlyAmountIn(AppCurrency target) =>
      CurrencyRates.convert(yearlyAmount, currencyCode, target.code);
  double amountIn(AppCurrency target) =>
      CurrencyRates.convert(amount, currencyCode, target.code);

  // ── Derived dates ─────────────────────────────────────────────────────
  DateTime get nextPaymentDate =>
      Billing.nextPaymentDate(firstPaymentDate, cycle);
  int get daysUntilNextPayment => Billing.daysUntil(nextPaymentDate);
  double get periodProgress => Billing.periodProgress(firstPaymentDate, cycle);

  /// Cospa: cost per single use, in the subscription's own currency (monthly
  /// spend ÷ monthly uses). Null when usage isn't tracked.
  double? get costPerUse {
    if (usageCount <= 0) return null;
    return monthlyAmount / usageCount;
  }

  Subscription copyWith({
    String? name,
    double? amount,
    String? currencyCode,
    BillingCycle? cycle,
    DateTime? firstPaymentDate,
    int? colorValue,
    String? emoji,
    Object? categoryId = _sentinel,
    Object? paymentMethodId = _sentinel,
    Object? memo = _sentinel,
    double? usageCount,
    String? usageUnit,
    bool? isPaused,
    Object? imagePath = _sentinel,
    List<NotifyRule>? notifyRules,
    int? sortOrder,
  }) =>
      Subscription(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        currencyCode: currencyCode ?? this.currencyCode,
        cycle: cycle ?? this.cycle,
        firstPaymentDate: firstPaymentDate ?? this.firstPaymentDate,
        colorValue: colorValue ?? this.colorValue,
        emoji: emoji ?? this.emoji,
        categoryId:
            categoryId == _sentinel ? this.categoryId : categoryId as String?,
        paymentMethodId: paymentMethodId == _sentinel
            ? this.paymentMethodId
            : paymentMethodId as String?,
        memo: memo == _sentinel ? this.memo : memo as String?,
        usageCount: usageCount ?? this.usageCount,
        usageUnit: usageUnit ?? this.usageUnit,
        isPaused: isPaused ?? this.isPaused,
        imagePath:
            imagePath == _sentinel ? this.imagePath : imagePath as String?,
        notifyRules: notifyRules ?? this.notifyRules,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'currency': currencyCode,
        'cycle': cycle.name,
        'first_payment': firstPaymentDate.millisecondsSinceEpoch,
        'color': colorValue,
        'emoji': emoji,
        'category_id': categoryId,
        'payment_method_id': paymentMethodId,
        'memo': memo,
        'usage_count': usageCount,
        'usage_unit': usageUnit,
        'is_paused': isPaused ? 1 : 0,
        'image_path': imagePath,
        'notify_days': NotifyRule.encode(notifyRules),
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Subscription.fromMap(Map<String, Object?> m) => Subscription(
        id: m['id'] as String,
        name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        currencyCode: m['currency'] as String,
        cycle: BillingCycleX.fromName(m['cycle'] as String?),
        firstPaymentDate:
            DateTime.fromMillisecondsSinceEpoch(m['first_payment'] as int),
        colorValue: m['color'] as int,
        emoji: m['emoji'] as String?,
        categoryId: m['category_id'] as String?,
        paymentMethodId: m['payment_method_id'] as String?,
        memo: m['memo'] as String?,
        usageCount: (m['usage_count'] as num?)?.toDouble() ?? 0,
        usageUnit: (m['usage_unit'] as String?) ?? '回',
        isPaused: (m['is_paused'] as int? ?? 0) == 1,
        imagePath: m['image_path'] as String?,
        notifyRules: NotifyRule.decode(m['notify_days'] as String?),
        sortOrder: m['sort_order'] as int? ?? 0,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  static const Object _sentinel = Object();
}
