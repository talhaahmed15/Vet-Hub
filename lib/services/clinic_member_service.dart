import 'dart:developer';

import 'package:clinic_management_app/models/clinic_member.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicMemberService {
  ClinicMemberService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const String _memberColumns =
      'id,full_name,role,account_status,phone';

  Future<String?> _getClinicId() async {
    final data = await Storage.getClinicData();
    final clinicId = data?['clinic_id']?.toString();
    if (clinicId == null || clinicId.isEmpty) {
      return null;
    }
    return clinicId;
  }

  Future<ClinicMember?> fetchCurrentMember() async {
    try {
      final storedClinicUserId = await Storage.getClinicUserId();
      if (storedClinicUserId != null && storedClinicUserId.isNotEmpty) {
        final row = await _supabase
            .from('clinic_users')
            .select(_memberColumns)
            .eq('id', storedClinicUserId)
            .maybeSingle();
        if (row != null) {
          return ClinicMember.fromMap(row);
        }
      }

      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null || authUserId.isEmpty) {
        return null;
      }

      final clinicId = await _getClinicId();
      final query = _supabase
          .from('clinic_users')
          .select(_memberColumns)
          .eq('auth_user_id', authUserId);
      final row = clinicId != null
          ? await query.eq('clinic_id', clinicId).maybeSingle()
          : await query.maybeSingle();
      return row != null ? ClinicMember.fromMap(row) : null;
    } catch (e) {
      log('Error fetching current clinic member: $e');
      return null;
    }
  }

  Future<List<ClinicMember>> fetchMembers() async {
    try {
      log('Fetching clinic members');
      final clinicId = await _getClinicId();
      final base = _supabase.from('clinic_users').select(_memberColumns);
      final filtered =
          clinicId != null ? base.eq('clinic_id', clinicId) : base;
      final data = await filtered.order('full_name', ascending: true);
      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return rows
          .map(ClinicMember.fromMap)
          .where((row) => row.id.isNotEmpty)
          .toList(growable: false);
    } catch (e) {
      log('Error fetching clinic members: $e');
      rethrow;
    }
  }

  Future<void> updateMember({
    required String memberId,
    String? fullName,
    String? role,
    String? accountStatus,
    String? phone,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (fullName != null) {
        payload['full_name'] = fullName.trim().isEmpty ? null : fullName.trim();
      }
      if (role != null && role.trim().isNotEmpty) {
        payload['role'] = role.trim();
      }
      if (accountStatus != null && accountStatus.trim().isNotEmpty) {
        payload['account_status'] = accountStatus.trim();
      }
      if (phone != null) {
        payload['phone'] = phone.trim().isEmpty ? null : phone.trim();
      }

      if (payload.isEmpty) {
        return;
      }

      await _supabase
          .from('clinic_users')
          .update(payload)
          .eq('id', memberId);
    } catch (e) {
      log('Error updating clinic member: $e');
      rethrow;
    }
  }

  Future<void> createMember({
    required String fullName,
    required String username,
    required String password,
    required String phone,
    required String role,
  }) async {
    final clinic = await Storage.getClinicData();
    final clinicCode = clinic?['clinic_code']?.toString();
    if (clinicCode == null || clinicCode.isEmpty) {
      throw StateError('Missing clinic_code in local storage');
    }
    try {
      final response = await _supabase.functions.invoke(
        'create-clinic-user',
        body: {
          'clinic_code': clinicCode,
          'full_name': fullName.trim(),
          'username': username.trim(),
          'password': password,
          'phone': phone.trim(),
          'role': role,
          'account_status': 'active',
        },
      );
      final data = response.data;
      if (data is Map && data['ok'] != true) {
        throw Exception(data['error']?.toString() ?? 'Failed to create user');
      }
    } catch (e) {
      log('Error creating clinic member: $e');
      rethrow;
    }
  }
}
