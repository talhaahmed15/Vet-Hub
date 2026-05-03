import 'dart:developer';
import 'dart:math' as math;

import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  final SupabaseClient _supabase;

  InventoryService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<String> _requireClinicId() async {
    final data = await Storage.getClinicData();
    final clinicId = data?['clinic_id']?.toString();
    if (clinicId == null || clinicId.isEmpty) {
      throw StateError('Missing clinic context. Please sign in again.');
    }
    return clinicId;
  }

  Future<List<InventoryTxn>> fetchTxnsForItem(
    String itemId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      log(
        'Fetching inventory transactions for item: $itemId limit=$limit offset=$offset',
      );
      final query = _supabase
          .from('inventory_txns')
          .select()
          .eq('clinic_id', clinicId)
          .eq('item_id', itemId)
          .order('created_at', ascending: false);

      final data = limit != null
          ? await query.range(offset ?? 0, (offset ?? 0) + limit - 1)
          : await query;
      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      log('Fetched inventory transactions for item $itemId: ${rows.length}');
      return rows.map(InventoryTxn.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      if (_isMissingClinicColumn(e)) {
        throw StateError(
          'Database schema is outdated: missing inventory_txns.clinic_id. Run latest Supabase migrations.',
        );
      }
      log('Error fetching inventory transactions for item $itemId: $e');
      rethrow;
    } catch (e) {
      log('Error fetching inventory transactions for item $itemId: $e');
      rethrow;
    }
  }

  Future<void> createTxn({
    required String itemId,
    required InventoryTxnType txnType,
    required double quantity,
    String? note,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      final safeQuantity = math.max(0, quantity.abs());
      final payload = <String, dynamic>{
        'clinic_id': clinicId,
        'item_id': itemId,
        'txn_type': txnType.value,
        'quantity': safeQuantity,
        'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
      };

      log(
        'Creating inventory transaction: item=$itemId type=${txnType.value} qty=$safeQuantity',
      );
      await _supabase.from('inventory_txns').insert(payload);
      log('Created inventory transaction for item: $itemId');
    } on PostgrestException catch (e) {
      if (_isMissingClinicColumn(e)) {
        throw StateError(
          'Database schema is outdated: missing inventory_txns.clinic_id. Run latest Supabase migrations.',
        );
      }
      log('Error creating inventory transaction for item $itemId: $e');
      rethrow;
    } catch (e) {
      log('Error creating inventory transaction for item $itemId: $e');
      rethrow;
    }
  }

  bool _isMissingClinicColumn(PostgrestException error) {
    return error.code == '42703' &&
        (error.message.contains('inventory_txns.clinic_id') ||
            error.message.contains('column clinic_id'));
  }
}
