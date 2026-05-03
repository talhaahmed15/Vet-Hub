import 'dart:developer';

import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemsService {
  final SupabaseClient _supabase;

  ItemsService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  static const String _columns =
      'id,name,category,price,unit,on_hand,is_active,created_at';

  Future<String> _requireClinicId() async {
    final data = await Storage.getClinicData();
    final clinicId = data?['clinic_id']?.toString();
    if (clinicId == null || clinicId.isEmpty) {
      throw StateError('Missing clinic context. Please sign in again.');
    }
    return clinicId;
  }

  Future<List<Item>> fetchItems({
    bool activeOnly = true,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      log(
        'Fetching items (activeOnly=$activeOnly, searchQuery=$searchQuery, limit=$limit, offset=$offset)',
      );
      final query = _supabase
          .from('items')
          .select(_columns)
          .eq('clinic_id', clinicId);
      if (activeOnly) {
        query.eq('is_active', true);
      }
      final trimmedQuery = searchQuery?.trim();
      final filtered = (trimmedQuery != null && trimmedQuery.isNotEmpty)
          ? query.or(
              'name.ilike.%$trimmedQuery%,category.ilike.%$trimmedQuery%',
            )
          : query;

      final ordered = filtered.order('name', ascending: true);
      final data = limit != null
          ? await ordered.range(offset ?? 0, (offset ?? 0) + limit - 1)
          : await ordered;
      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      log('Fetched items: ${rows.length}');
      return rows.map(Item.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      if (_isMissingClinicColumn(e)) {
        throw StateError(
          'Database schema is outdated: missing items.clinic_id. Run latest Supabase migrations.',
        );
      }
      log('Error fetching items: $e');
      rethrow;
    } catch (e) {
      log('Error fetching items: $e');
      rethrow;
    }
  }

  Future<Item> createItem({
    required String name,
    String? category,
    String unit = 'ea',
    double price = 0,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      final safePrice = price.isNaN ? 0 : price;
      final payload = <String, dynamic>{
        'clinic_id': clinicId,
        'name': name.trim(),
        'category': category?.trim().isEmpty ?? true ? null : category!.trim(),
        'price': safePrice,
        'unit': unit.trim().isEmpty ? 'ea' : unit.trim(),
      };

      log('Creating item: ${payload['name']}');
      final row = await _supabase
          .from('items')
          .insert(payload)
          .select(_columns)
          .single();
      log('Created item: ${row['id']}');
      return Item.fromMap(row);
    } on PostgrestException catch (e) {
      if (_isMissingClinicColumn(e)) {
        throw StateError(
          'Database schema is outdated: missing items.clinic_id. Run latest Supabase migrations.',
        );
      }
      log('Error creating item: $e');
      rethrow;
    } catch (e) {
      log('Error creating item: $e');
      rethrow;
    }
  }

  Future<Item> fetchItemById(String id) async {
    try {
      final clinicId = await _requireClinicId();
      log('Fetching item by id: $id');
      final row = await _supabase
          .from('items')
          .select(_columns)
          .eq('id', id)
          .eq('clinic_id', clinicId)
          .single();
      log('Fetched item by id: $id');
      return Item.fromMap(row);
    } on PostgrestException catch (e) {
      if (_isMissingClinicColumn(e)) {
        throw StateError(
          'Database schema is outdated: missing items.clinic_id. Run latest Supabase migrations.',
        );
      }
      log('Error fetching item by id $id: $e');
      rethrow;
    } catch (e) {
      log('Error fetching item by id $id: $e');
      rethrow;
    }
  }

  Future<Item> updateItem({
    required String id,
    required String name,
    String? category,
    required String unit,
    double price = 0,
    bool? isActive,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      final safePrice = price.isNaN ? 0 : price;
      final payload = <String, dynamic>{
        'name': name.trim(),
        'category': category?.trim().isEmpty ?? true ? null : category!.trim(),
        'price': safePrice,
        'unit': unit.trim().isEmpty ? 'ea' : unit.trim(),
        if (isActive != null) 'is_active': isActive,
      };

      log('Updating item: $id');
      final row = await _supabase
          .from('items')
          .update(payload)
          .eq('id', id)
          .eq('clinic_id', clinicId)
          .select(_columns)
          .single();
      log('Updated item: $id');
      return Item.fromMap(row);
    } on PostgrestException catch (e) {
      if (_isMissingClinicColumn(e)) {
        throw StateError(
          'Database schema is outdated: missing items.clinic_id. Run latest Supabase migrations.',
        );
      }
      log('Error updating item $id: $e');
      rethrow;
    } catch (e) {
      log('Error updating item $id: $e');
      rethrow;
    }
  }

  bool _isMissingClinicColumn(PostgrestException error) {
    return error.code == '42703' &&
        (error.message.contains('items.clinic_id') ||
            error.message.contains('column clinic_id'));
  }
}
