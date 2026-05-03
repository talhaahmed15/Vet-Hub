import 'dart:developer';

import 'package:clinic_management_app/models/appointment_detail.dart';
import 'package:clinic_management_app/models/appointment_summary.dart';
import 'package:clinic_management_app/models/clinic_user.dart';
import 'package:clinic_management_app/models/client.dart';
import 'package:clinic_management_app/models/pet.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentService {
  final SupabaseClient _supabase;

  AppointmentService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  static const String _clientColumns = 'id,full_name,phone';
  static const String _petColumns = 'id,client_id,name,species,breed';
  static const String _clinicUserColumns = 'id';
  static const String _clinicUserListColumns = 'id,full_name';
  static const String _appointmentSummaryColumns =
      'id,client_id,doctor_id,created_at,appointment_reason,condition_status,condition_notes,temperature,heart_rate,weight_kg,client:clients!inner(id,full_name,phone,clinic_id),pet:pets(id,name,species,breed)';
  static const String _appointmentDetailColumns =
      'id,client_id,pet_id,doctor_id,created_at,appointment_reason,condition_status,condition_notes,temperature,heart_rate,weight_kg,prescriptions,client:clients!inner(id,full_name,phone,clinic_id),pet:pets(id,name,species,breed),doctor:clinic_users(id,full_name)';

  Future<String?> _getClinicId() async {
    final data = await Storage.getClinicData();
    final clinicId = data?['clinic_id']?.toString();
    if (clinicId == null || clinicId.isEmpty) {
      return null;
    }
    return clinicId;
  }

  Future<String> _requireClinicId() async {
    final clinicId = await _getClinicId();
    if (clinicId == null || clinicId.isEmpty) {
      throw StateError('Missing clinic context. Please sign in again.');
    }
    return clinicId;
  }

  Future<List<Client>> fetchClients() async {
    try {
      log('Fetching clients');
      final clinicId = await _requireClinicId();
      final query = _supabase
          .from('clients')
          .select(_clientColumns)
          .eq('clinic_id', clinicId);

      final data = await query.order('full_name', ascending: true);
      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      log('Fetched clients: ${rows.length}');
      return rows.map(Client.fromMap).toList(growable: false);
    } catch (e) {
      log('Error fetching clients: $e');
      rethrow;
    }
  }

  Future<List<ClinicUser>> fetchClinicUsers() async {
    try {
      log('Fetching clinic users');
      final clinicId = await _requireClinicId();
      final query = _supabase
          .from('clinic_users')
          .select(_clinicUserListColumns)
          .eq('clinic_id', clinicId);

      final data = await query.order('full_name', ascending: true);
      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return rows
          .map(ClinicUser.fromMap)
          .where((row) => row.id.isNotEmpty)
          .toList(growable: false);
    } catch (e) {
      log('Error fetching clinic users: $e');
      rethrow;
    }
  }

  Future<List<Pet>> fetchPetsByClientId(String clientId) async {
    try {
      final clinicId = await _requireClinicId();
      log('Fetching pets for client: $clientId');
      final ownedClient = await _supabase
          .from('clients')
          .select('id')
          .eq('id', clientId)
          .eq('clinic_id', clinicId)
          .maybeSingle();
      if (ownedClient == null) {
        return const <Pet>[];
      }
      final data = await _supabase
          .from('pets')
          .select(_petColumns)
          .eq('client_id', clientId)
          .order('name', ascending: true);
      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      log('Fetched pets for client $clientId: ${rows.length}');
      return rows.map(Pet.fromMap).toList(growable: false);
    } catch (e) {
      log('Error fetching pets for client $clientId: $e');
      rethrow;
    }
  }

  Future<String?> _getCurrentClinicUserId() async {
    final storedClinicUserId = await Storage.getClinicUserId();
    if (storedClinicUserId != null && storedClinicUserId.isNotEmpty) {
      return storedClinicUserId;
    }

    final authUserId = _supabase.auth.currentUser?.id;
    if (authUserId == null || authUserId.isEmpty) {
      return null;
    }

    final clinicId = await _requireClinicId();
    final query = _supabase
        .from('clinic_users')
        .select(_clinicUserColumns)
        .eq('auth_user_id', authUserId);
    final row = await query.eq('clinic_id', clinicId).maybeSingle();
    final clinicUserId = row?['id']?.toString();
    if (clinicUserId != null && clinicUserId.isNotEmpty) {
      return clinicUserId;
    }
    return null;
  }

  Future<List<AppointmentSummary>> fetchRecentAppointments({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    String? species,
    String? billingStatus,
    String? veterinarianId,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      final base = _supabase
          .from('appointments')
          .select(_appointmentSummaryColumns)
          .eq('client.clinic_id', clinicId);
      var filtered = base;

      if (startDate != null) {
        filtered = filtered.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        final inclusiveEnd = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
        filtered = filtered.lte('created_at', inclusiveEnd.toIso8601String());
      }
      if (species != null && species.trim().isNotEmpty) {
        filtered = filtered.ilike('pet.species', '%${species.trim()}%');
      }
      if (veterinarianId != null && veterinarianId.trim().isNotEmpty) {
        filtered = filtered.eq('doctor_id', veterinarianId.trim());
      }

      final data = await filtered
          .order('created_at', ascending: false)
          .limit(limit);
      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      final summaries = rows
          .map(AppointmentSummary.fromMap)
          .where((row) => row.id.isNotEmpty)
          .toList(growable: false);

      var filteredSummaries = summaries;
      if (species != null && species.trim().isNotEmpty) {
        final target = species.trim().toLowerCase();
        filteredSummaries =
            filteredSummaries
                .where(
                  (row) => row.petSpecies.trim().isNotEmpty
                      ? row.petSpecies.toLowerCase().contains(target)
                      : false,
                )
                .toList(growable: false);
      }
      if (billingStatus != null &&
          billingStatus.isNotEmpty &&
          billingStatus != 'all') {
        final appointmentIds = filteredSummaries
            .map((row) => row.id)
            .where((id) => id.isNotEmpty)
            .toList(growable: false);
        if (appointmentIds.isNotEmpty) {
          final invoiceQuery = _supabase
              .from('invoices')
              .select('appointment_id')
              .eq('clinic_id', clinicId)
              .inFilter('appointment_id', appointmentIds);
          final invoiceRows =
              (await invoiceQuery) as List<dynamic>? ?? const [];
          final billedIds =
              invoiceRows
                  .map((row) => (row as Map<String, dynamic>)['appointment_id'])
                  .map((value) => value?.toString() ?? '')
                  .where((id) => id.isNotEmpty)
                  .toSet();

          if (billingStatus == 'billed') {
            filteredSummaries =
                filteredSummaries
                    .where((row) => billedIds.contains(row.id))
                    .toList(growable: false);
          } else if (billingStatus == 'unbilled') {
            filteredSummaries =
                filteredSummaries
                    .where((row) => !billedIds.contains(row.id))
                    .toList(growable: false);
          }
        }
      }

      final missingClientIds = filteredSummaries
          .where(
            (row) =>
                row.ownerName.trim().isEmpty && row.clientId.trim().isNotEmpty,
          )
          .map((row) => row.clientId)
          .toSet()
          .toList(growable: false);

      if (missingClientIds.isEmpty) {
        return filteredSummaries;
      }

      final clientRows = await _supabase
          .from('clients')
          .select(_clientColumns)
          .eq('clinic_id', clinicId)
          .inFilter('id', missingClientIds);
      final clientMaps = (clientRows as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final clientById = {
        for (final row in clientMaps) row['id']?.toString() ?? '': row,
      };

      return filteredSummaries
          .map((row) {
            if (row.ownerName.trim().isNotEmpty) return row;
            final client = clientById[row.clientId];
            if (client == null) return row;
            return row.copyWith(
              ownerName: client['full_name']?.toString() ?? '',
              ownerPhone: client['phone']?.toString() ?? '',
            );
          })
          .toList(growable: false);
    } catch (e) {
      log('Error fetching appointments: $e');
      rethrow;
    }
  }

  Future<AppointmentDetail?> fetchAppointmentById(String appointmentId) async {
    try {
      final clinicId = await _requireClinicId();
      final row = await _supabase
          .from('appointments')
          .select(_appointmentDetailColumns)
          .eq('id', appointmentId)
          .eq('client.clinic_id', clinicId)
          .maybeSingle();
      if (row == null) return null;
      return AppointmentDetail.fromMap(row);
    } catch (e) {
      log('Error fetching appointment $appointmentId: $e');
      rethrow;
    }
  }

  Future<Client> createClient({required String fullName, String? phone}) async {
    try {
      final clinicId = await _requireClinicId();
      final payload = <String, dynamic>{
        'full_name': fullName.trim(),
        'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
      };
      payload['clinic_id'] = clinicId;
      log('Creating client: ${payload['full_name']}');
      final row = await _supabase
          .from('clients')
          .insert(payload)
          .select(_clientColumns)
          .single();
      log('Created client: ${row['id']}');
      return Client.fromMap(row);
    } catch (e) {
      log('Error creating client: $e');
      rethrow;
    }
  }

  Future<Pet> createPet({
    required String clientId,
    required String name,
    required String species,
    String? breed,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      final ownedClient = await _supabase
          .from('clients')
          .select('id')
          .eq('id', clientId)
          .eq('clinic_id', clinicId)
          .maybeSingle();
      if (ownedClient == null) {
        throw StateError('Client does not belong to this clinic.');
      }
      final payload = <String, dynamic>{
        'client_id': clientId,
        'name': name.trim(),
        'species': species.trim(),
        'breed': breed?.trim().isEmpty ?? true ? null : breed!.trim(),
      };
      log('Creating pet: ${payload['name']} for client $clientId');
      final row = await _supabase
          .from('pets')
          .insert(payload)
          .select(_petColumns)
          .single();
      log('Created pet: ${row['id']}');
      return Pet.fromMap(row);
    } catch (e) {
      log('Error creating pet: $e');
      rethrow;
    }
  }

  Future<Pet> updatePet({
    required String petId,
    required String name,
    required String species,
    String? breed,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      final ownedPet = await _supabase
          .from('pets')
          .select('id,client:clients!inner(id,clinic_id)')
          .eq('id', petId)
          .eq('client.clinic_id', clinicId)
          .maybeSingle();
      if (ownedPet == null) {
        throw StateError('Pet does not belong to this clinic.');
      }
      final payload = <String, dynamic>{
        'name': name.trim(),
        'species': species.trim(),
        'breed': breed?.trim().isEmpty ?? true ? null : breed!.trim(),
      };
      log('Updating pet $petId');
      final row = await _supabase
          .from('pets')
          .update(payload)
          .eq('id', petId)
          .select(_petColumns)
          .single();
      log('Updated pet $petId');
      return Pet.fromMap(row);
    } catch (e) {
      log('Error updating pet $petId: $e');
      rethrow;
    }
  }

  Future<void> deletePet(String petId) async {
    try {
      final clinicId = await _requireClinicId();
      final ownedPet = await _supabase
          .from('pets')
          .select('id,client:clients!inner(id,clinic_id)')
          .eq('id', petId)
          .eq('client.clinic_id', clinicId)
          .maybeSingle();
      if (ownedPet == null) {
        throw StateError('Pet does not belong to this clinic.');
      }
      log('Deleting pet $petId');
      await _supabase.from('pets').delete().eq('id', petId);
      log('Deleted pet $petId');
    } catch (e) {
      log('Error deleting pet $petId: $e');
      rethrow;
    }
  }

  Future<String> createAppointment({
    required String clientId,
    required String petId,
    required String appointmentReason,
    required String conditionStatus,
    required String conditionNotes,
    required String temperature,
    required String weightKg,
    required String heartRate,
    required List<Map<String, dynamic>> prescriptions,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      final ownedClient = await _supabase
          .from('clients')
          .select('id')
          .eq('id', clientId)
          .eq('clinic_id', clinicId)
          .maybeSingle();
      if (ownedClient == null) {
        throw StateError('Client does not belong to this clinic.');
      }
      final ownedPet = await _supabase
          .from('pets')
          .select('id')
          .eq('id', petId)
          .eq('client_id', clientId)
          .maybeSingle();
      if (ownedPet == null) {
        throw StateError('Pet does not belong to the selected client.');
      }
      final doctorId = await _getCurrentClinicUserId();
      if (doctorId == null || doctorId.isEmpty) {
        log('No clinic user found for current auth user; doctor_id not set.');
      }
      final payload = <String, dynamic>{
        'client_id': clientId,
        'pet_id': petId,
        'appointment_reason': appointmentReason.trim().isEmpty
            ? null
            : appointmentReason.trim(),
        'condition_status': conditionStatus.trim().isEmpty
            ? null
            : conditionStatus.trim(),
        'condition_notes': conditionNotes.trim().isEmpty
            ? null
            : conditionNotes.trim(),
        'temperature': temperature.trim().isEmpty ? null : temperature.trim(),
        'weight_kg': weightKg.trim().isEmpty ? null : weightKg.trim(),
        'heart_rate': heartRate.trim().isEmpty ? null : heartRate.trim(),
        'prescriptions': prescriptions,
      };
      if (doctorId != null && doctorId.isNotEmpty) {
        payload['doctor_id'] = doctorId;
      }

      log('Creating appointment for client $clientId and pet $petId');
      final row = await _supabase
          .from('appointments')
          .insert(payload)
          .select('id')
          .single();
      log('Created appointment for client $clientId and pet $petId');
      return row['id']?.toString() ?? '';
    } catch (e) {
      log('Error creating appointment: $e');
      rethrow;
    }
  }
}
