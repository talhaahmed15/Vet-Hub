import 'dart:developer';

import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicAccountService {
  ClinicAccountService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<void> createClinicAccount({
    required String clinicCode,
    required String fullName,
    required String username,
    required String password,
    required ClinicRole role,
    String? phone,
  }) async {
    try {
      log('Creating clinic account for clinicCode=$clinicCode role=${role.value}');
      final accessToken = _supabase.auth.currentSession?.accessToken;
      final response = await _supabase.functions.invoke(
        'create-clinic-user',
        headers:
            accessToken != null && accessToken.isNotEmpty
                ? {'Authorization': 'Bearer $accessToken'}
                : null,
        body: {
          'clinic_code': clinicCode,
          'full_name': fullName,
          'username': username,
          'password': password,
          'role': role.value,
          'phone': phone,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw "No response from server";
      }

      if (data['ok'] != true) {
        throw data['error']?.toString() ?? "Signup failed";
      }
      log('Created clinic account for clinicCode=$clinicCode username=$username');
    } catch (e) {
      log('Error creating clinic account: $e');
      rethrow;
    }
  }
}
