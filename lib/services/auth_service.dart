import 'dart:developer';

import 'package:clinic_management_app/services/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountStatusResult {
  final String status;
  final String? userId;

  const AccountStatusResult({required this.status, this.userId});
}

class AuthService {
  AuthService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<AccountStatusResult> loginWithUsername({
    required String clinicCode,
    required String username,
    required String password,
    String? clinicId,
  }) async {
    log('Logging in with username for clinicCode=$clinicCode clinicId=$clinicId');
    final response = await _supabase.functions.invoke(
      'login-username',
      body: {
        'clinic_code': clinicCode,
        'username': username,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['ok'] != true) {
      throw data?['error']?.toString() ?? "Unable to sign in.";
    }

    final session = data['session'] as Map<String, dynamic>?;
    if (session == null) {
      throw "Unable to create session.";
    }

    await _supabase.auth.setSession(
      // session['access_token'] as String,
      session['refresh_token'] as String,
    );

    final userId = (data['user'] as Map<String, dynamic>?)?['id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw "Unable to load account status.";
    }


    final query = _supabase
        .from('clinic_users')
        .select('id,account_status')
        .eq('auth_user_id', userId);
    final responseRow = clinicId != null && clinicId.isNotEmpty
        ? await query.eq('clinic_id', clinicId).maybeSingle()
        : await query.maybeSingle();

    final row = responseRow;
    if (row == null) {
      throw "Account not found for this clinic.";
    }

    final clinicUserId = row['id']?.toString();
    final status = (row['account_status'] ?? '').toString();
    log('Loaded account status for user $userId: $status');

    await Storage.saveAuthSession(
      refreshToken: session['refresh_token'] as String,
      userId: userId,
      clinicUserId: clinicUserId,
    );
    return AccountStatusResult(status: status, userId: userId);
  }

  Future<bool> restoreSession() async {
    log('Restoring auth session');
    final existing = _supabase.auth.currentSession;
    if (existing != null) {
      log('Auth session already active');
      return true;
    }

    final refreshToken = await Storage.getRefreshToken();
    if (refreshToken == null) {
      log('No refresh token found');
      return false;
    }

    try {
      await _supabase.auth.setSession(refreshToken);
      log('Auth session restored');
      return _supabase.auth.currentSession != null;
    } catch (_) {
      log('Failed to restore auth session, clearing storage');
      await Storage.clearAuthSession();
      return false;
    }
  }

  Future<String?> fetchClinicUserId({String? clinicId}) async {
    final authUserId = _supabase.auth.currentUser?.id;
    if (authUserId == null || authUserId.isEmpty) {
      return null;
    }

    final query = _supabase
        .from('clinic_users')
        .select('id')
        .eq('auth_user_id', authUserId);
    final row = clinicId != null && clinicId.isNotEmpty
        ? await query.eq('clinic_id', clinicId).maybeSingle()
        : await query.maybeSingle();
    return row?['id']?.toString();
  }

  Future<void> signOutAndClear({bool clearClinic = false}) async {
    log('Signing out (clearClinic=$clearClinic)');
    try {
      await _supabase.auth.signOut();
    } finally {
      if (clearClinic) {
        await Storage.clearAllAuthAndClinic();
      } else {
        await Storage.clearAuthSession();
      }
      log('Sign out complete (clearClinic=$clearClinic)');
    }
  }
}
