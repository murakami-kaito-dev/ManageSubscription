import 'package:flutter/material.dart';

import '../../core/icon_registry.dart';
import '../../core/theme/app_colors.dart';

@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
    this.colorValue = _defaultColor,
  });

  static const int _defaultColor = 0xFF546C60; // primaryDeep

  final String id;
  final String name;
  final int icon;
  final int sortOrder;
  final int colorValue;

  Color get color => Color(colorValue);

  IconData get iconData =>
      IconRegistry.resolve(icon, fallback: IconRegistry.fallbackPayment);

  /// The three seeded methods (ids pm_0..) can't be deleted, only restyled.
  bool get isBuiltIn => id.startsWith('pm_');

  PaymentMethod copyWith(
          {String? name, int? icon, int? sortOrder, int? colorValue}) =>
      PaymentMethod(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
        colorValue: colorValue ?? this.colorValue,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
        'color': colorValue,
      };

  factory PaymentMethod.fromMap(Map<String, Object?> m) => PaymentMethod(
        id: m['id'] as String,
        name: m['name'] as String,
        icon: m['icon'] as int,
        sortOrder: m['sort_order'] as int,
        colorValue: (m['color'] as int?) ?? AppColors.primaryDeep.value,
      );
}
