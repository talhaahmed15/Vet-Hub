import 'dart:developer';

import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupOtpResult {
  final String? userId;
  final bool isVerified;

  const SignupOtpResult({this.userId, this.isVerified = false});
}

class ClinicAccountService {
  ClinicAccountService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<SignupOtpResult> sendSignupOtp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final isVerified =
          response.session != null || response.user?.emailConfirmedAt != null;
      return SignupOtpResult(userId: response.user?.id, isVerified: isVerified);
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('already registered') ||
          message.contains('already exists')) {
        await _supabase.auth.resend(type: OtpType.signup, email: email);
        return const SignupOtpResult();
      }
      rethrow;
    }
  }

  Future<String?> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.signup,
      email: email,
      token: token,
    );
    if (response.user == null) {
      throw "Unable to verify OTP";
    }
    return response.user?.id;
  }

  Future<void> createClinicAccount({
    required String clinicCode,
    required String fullName,
    required String email,
    required String password,
    required ClinicRole role,
    String? phone,
    String? authUserId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-clinic-user',
        body: {
          'clinic_code': clinicCode,
          'full_name': fullName,
          'email': email,
          'password': password,
          'role': role.value,
          'phone': phone,
          if (authUserId != null) 'auth_user_id': authUserId,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw "No response from server";
      }

      if (data['ok'] != true) {
        throw data['error']?.toString() ?? "Signup failed";
      }
    } catch (e) {
      log('Error creating clinic account: $e');
      rethrow;
    }
  }
}
