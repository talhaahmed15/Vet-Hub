import 'package:flutter/foundation.dart';

@immutable
class Item {
  const Item({
    required this.id,
    required this.name,
    this.category,
    required this.price,
    required this.unit,
    required this.onHand,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? category;
  final double price;
  final String unit;
  final double onHand;
  final bool isActive;
  final DateTime createdAt;

  Item copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? unit,
    double? onHand,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      onHand: onHand ?? this.onHand,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    final rawCategory = (map['category'] as String?)?.trim();
    final rawUnit = (map['unit'] as String?)?.trim();

    return Item(
      id: map['id'] as String,
      name: (map['name'] as String?)?.trim() ?? '',
      category: (rawCategory == null || rawCategory.isEmpty)
          ? null
          : rawCategory,
      price: _parseNumeric(map['price']),
      unit: (rawUnit == null || rawUnit.isEmpty) ? 'ea' : rawUnit,
      onHand: _parseNumeric(map['on_hand']),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'on_hand': onHand,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

double _parseNumeric(dynamic value) {
  if (value == null) return 0;

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0;
  }

  return 0;
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}
