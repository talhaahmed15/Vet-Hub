import 'dart:convert';

import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _clinicKey = 'clinic_data';

  // /// Save logged-in user data (Map, Model.toJson(), etc.)
  // static Future<void> saveUser(UserModel user) async {
  //   await _storage.write(key: 'user', value: jsonEncode(user));
  // }

  // /// Retrieve saved user
  // static Future<dynamic> getUser() async {
  //   final value = await _storage.read(key: 'user');
  //   return value != null ? jsonDecode(value) : null;
  // }

  // /// Delete saved user
  // static Future<void> clearUser() async {
  //   await _storage.delete(key: 'user');
  // }

  // /// Save authentication token
  // static Future<void> saveToken(String token) async {
  //   await _storage.write(key: 'token', value: token);
  // }

  // /// Retrieve saved token
  // static Future<String> getToken() async {
  //   return await _storage.read(key: 'token') ?? "";
  // }

  // /// Delete auth token
  // static Future<void> clearToken() async {
  //   await _storage.delete(key: 'token');
  // }

  // /// Logout → clear everything
  // static Future<void> logout() async {
  //   await _storage.deleteAll();
  // }

  // // ================================
  // // PROFILE DRAFT (SAVE FOR LATER)
  // // ================================

  // static Future<void> saveProfileDraft(Map<String, dynamic> data) async {
  //   log("Saved Draft: $data");

  //   await _storage.write(key: 'profile_draft', value: jsonEncode(data));
  // }

  // static Future<Map<String, dynamic>?> getProfileDraft() async {
  //   final value = await _storage.read(key: 'profile_draft');

  //   log("Loaded Draft $value");

  //   return value != null ? jsonDecode(value) : null;
  // }

  // static Future<void> clearProfileDraft() async {
  //   await _storage.delete(key: 'profile_draft');
  // }

  static Future<void> saveClinic(Clinic clinic) async {
    final payload = clinic.toMap()
      ..['clinic_id'] = clinic.clinicId
      ..['clinic_code'] = clinic.clinicCode;
    await _storage.write(key: _clinicKey, value: jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> getClinicData() async {
    final value = await _storage.read(key: _clinicKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return jsonDecode(value) as Map<String, dynamic>;
  }

  static Future<String?> getClinicCode() async {
    final data = await getClinicData();
    final code = data?['clinic_code']?.toString();
    if (code == null || code.isEmpty) {
      return null;
    }
    return code;
  }

  static Future<void> clearClinic() async {
    await _storage.delete(key: _clinicKey);
  }
}
