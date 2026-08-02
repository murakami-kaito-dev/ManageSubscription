import 'package:flutter/material.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.icon,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int colorValue;
  final int icon; // IconData codepoint
  final int sortOrder;

  Color get color => Color(colorValue);
  IconData get iconData =>
      IconData(icon, fontFamily: 'MaterialIcons');

  Category copyWith({
    String? name,
    int? colorValue,
    int? icon,
    int? sortOrder,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'color': colorValue,
        'icon': icon,
        'sort_order': sortOrder,
      };

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as String,
        name: m['name'] as String,
        colorValue: m['color'] as int,
        icon: m['icon'] as int,
        sortOrder: m['sort_order'] as int,
      );
}
