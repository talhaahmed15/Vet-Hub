import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicService {
  final SupabaseClient _supabase;

  ClinicService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Add a new clinic
  Future<Clinic?> addClinic(Clinic clinic) async {
    try {
      log('Creating clinic: ${clinic.clinicName ?? ''}');
      final payload = _buildCreateClinicPayload(clinic);
      final response = await _supabase.functions.invoke(
        'create-clinic',
        body: payload,
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw "No response from server";
      }

      if (data['ok'] != true) {
        throw data['error']?.toString() ?? "Clinic creation failed";
      }

      final clinicMap = data['clinic'] as Map<String, dynamic>?;
      if (clinicMap == null) {
        throw "Missing clinic response";
      }

      log("Response: ${clinicMap.toString()}");

      return Clinic.fromMap(clinicMap);
    } catch (e) {
      log('Error adding clinic: $e');
      rethrow;
    }
  }

  /// Fetch clinic by clinic code
  Future<Clinic?> getClinicByCode(String clinicCode) async {
    try {
      log('Fetching clinic by code: $clinicCode');
      final response = await _supabase
          .from('clinics')
          .select()
          .eq('clinic_code', clinicCode)
          .single();

      final data = response as Map<String, dynamic>?;

      log("Fetched Clinic: ${data.toString()}");

      return data != null ? Clinic.fromMap(data) : null;
    } catch (e) {
      log('Error fetching clinic by code: $e');
      return null;
    }
  }

  /// Update clinic profile details
  Future<Clinic?> updateClinic({
    required Clinic clinic,
  }) async {
    try {
      final clinicId = clinic.clinicId;
      if (clinicId == null || clinicId.isEmpty) {
        throw "Missing clinic id.";
      }

      final payload = clinic.toMap()
        ..['is_certified'] = false;

      final row = await _supabase
          .from('clinics')
          .update(payload)
          .eq('clinic_id', clinicId)
          .select()
          .single();
      return Clinic.fromMap(row);
    } catch (e) {
      log('Error updating clinic: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _buildCreateClinicPayload(Clinic clinic) {
    final payload = clinic.toMap();

    final logoPath = clinic.logoUrl;
    if (logoPath != null && !_isRemotePath(logoPath)) {
      payload['logo_file'] = _encodeFile(logoPath);
      payload['logo_url'] = null;
    }

    final certificatePath = clinic.certificateUrl;
    if (certificatePath != null && !_isRemotePath(certificatePath)) {
      payload['certificate_file'] = _encodeFile(certificatePath);
      payload['certificate_url'] = null;
    }

    final paymentProofPath = clinic.paymentProofUrl;
    if (paymentProofPath != null && !_isRemotePath(paymentProofPath)) {
      payload['payment_proof_file'] = _encodeFile(paymentProofPath);
      payload['payment_proof_url'] = null;
    }

    return payload;
  }

  Map<String, String> _encodeFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw "File not found: $path";
    }
    final bytes = file.readAsBytesSync();
    final extension = _fileExtension(path);
    return {
      'name': _fileName(path),
      'content_type': _contentTypeFromExtension(extension),
      'data_base64': base64Encode(bytes),
    };
  }

  String _contentTypeFromExtension(String extension) {
    final lower = extension.toLowerCase();
    if (lower == '.png') return 'image/png';
    if (lower == '.jpg' || lower == '.jpeg') return 'image/jpeg';
    if (lower == '.pdf') return 'application/pdf';
    return 'application/octet-stream';
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  bool _isRemotePath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  String _fileExtension(String? path) {
    if (path == null || path.isEmpty || !path.contains('.')) {
      return '';
    }
    return path.substring(path.lastIndexOf('.'));
  }
}
