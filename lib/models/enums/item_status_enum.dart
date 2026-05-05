import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:flutter/material.dart';

enum InventoryStatus { lowStock, inStock, outOfStock }

extension InventoryStatusX on InventoryStatus {
  String get label => switch (this) {
    InventoryStatus.lowStock => 'Low Stock',
    InventoryStatus.inStock => 'In Stock',
    InventoryStatus.outOfStock => 'Out of Stock',
  };

  Color get foreground => switch (this) {
    InventoryStatus.lowStock => const Color(0xFFB35A00),
    InventoryStatus.inStock => const Color(0xFF1C8C3A),
    InventoryStatus.outOfStock => AppColors.error,
  };

  Color get background => switch (this) {
    InventoryStatus.lowStock => const Color(0xFFFFF4E5),
    InventoryStatus.inStock => const Color(0xFFE9F8EE),
    InventoryStatus.outOfStock => const Color(0xFFFFE9E9),
  };

  Color get border => foreground.withValues(alpha: 0.2);

  // String trailingLabel(double minThreshold) => switch (this) {
  //   InventoryStatus.lowStock => 'Min: ${formatQuantity(minThreshold)}',
  //   InventoryStatus.inStock => 'Stock OK',
  //   InventoryStatus.outOfStock => 'Reorder',
  // };
}

InventoryStatus statusFor(double onHand, double minThreshold) {
  if (onHand <= 0) return InventoryStatus.outOfStock;
  if (onHand <= minThreshold) return InventoryStatus.lowStock;
  return InventoryStatus.inStock;
}

double minThresholdFor(String? category) {
  final value = (category ?? '').toLowerCase();
  if (value.contains('equip')) return 2;
  if (value.contains('consum')) return 50;
  if (value.contains('med') || value.contains('vacc')) return 20;
  return 10;
}

String unitLabel(String unit) {
  final normalized = unit.trim();
  if (normalized.isEmpty) return 'units';
  return normalized.toLowerCase();
}

String formatQuantity(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
