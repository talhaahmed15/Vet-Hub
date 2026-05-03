import 'dart:developer';

import 'package:clinic_management_app/models/package_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PackageService {
  PackageService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<PackagePlan>> fetchPackages() async {
    try {
      final rows = await _supabase
          .from('packages')
          .select()
          .eq('is_active', true)
          .order('trial_days', ascending: false)
          .order('price_cents', ascending: true);
      final list = (rows as List<dynamic>)
          .map((row) => PackagePlan.fromMap(row as Map<String, dynamic>))
          .toList(growable: false);
      return list;
    } catch (e) {
      log('Error fetching packages: $e');
      rethrow;
    }
  }
}
