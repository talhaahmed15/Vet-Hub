import 'package:flutter/foundation.dart';

enum InventoryTxnType { receive, use, waste, adjust }

extension InventoryTxnTypeX on InventoryTxnType {
  String get value {
    switch (this) {
      case InventoryTxnType.receive:
        return 'receive';
      case InventoryTxnType.use:
        return 'use';
      case InventoryTxnType.waste:
        return 'waste';
      case InventoryTxnType.adjust:
        return 'adjust';
    }
  }

  String get label {
    switch (this) {
      case InventoryTxnType.receive:
        return 'Receive';
      case InventoryTxnType.use:
        return 'Use';
      case InventoryTxnType.waste:
        return 'Waste';
      case InventoryTxnType.adjust:
        return 'Adjust';
    }
  }

  static InventoryTxnType fromValue(String raw) {
    switch (raw) {
      case 'receive':
        return InventoryTxnType.receive;
      case 'use':
        return InventoryTxnType.use;
      case 'waste':
        return InventoryTxnType.waste;
      case 'adjust':
        return InventoryTxnType.adjust;
      default:
        return InventoryTxnType.receive;
    }
  }
}

@immutable
class InventoryTxn {
  const InventoryTxn({
    required this.id,
    required this.itemId,
    required this.txnType,
    required this.quantity,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String itemId;
  final InventoryTxnType txnType;
  final double quantity;
  final String? note;
  final DateTime createdAt;

  factory InventoryTxn.fromMap(Map<String, dynamic> map) {
    return InventoryTxn(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      txnType:
          InventoryTxnTypeX.fromValue(map['txn_type'] as String? ?? 'receive'),
      quantity: _parseNumeric(map['quantity']),
      note: (map['note'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['note'] as String?)?.trim(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return <String, dynamic>{
      'item_id': itemId,
      'txn_type': txnType.value,
      'quantity': quantity,
      'note': note,
    };
  }
}

double _parseNumeric(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

