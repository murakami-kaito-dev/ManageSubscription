import 'package:flutter/material.dart';

import '../../core/icon_registry.dart';

@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int icon;
  final int sortOrder;

  IconData get iconData =>
      IconRegistry.resolve(icon, fallback: IconRegistry.fallbackPayment);

  PaymentMethod copyWith({String? name, int? icon, int? sortOrder}) =>
      PaymentMethod(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
      };

  factory PaymentMethod.fromMap(Map<String, Object?> m) => PaymentMethod(
        id: m['id'] as String,
        name: m['name'] as String,
        icon: m['icon'] as int,
        sortOrder: m['sort_order'] as int,
      );
}
