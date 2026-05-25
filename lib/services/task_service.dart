import 'dart:developer';

import 'package:clinic_management_app/models/task.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  TaskService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const String _columns =
      'id,clinic_id,title,description,assignee_id,status,created_by,'
      'created_at,updated_at,'
      'assignee:clinic_users!clinic_tasks_assignee_id_fkey(full_name)';

  Future<String?> _clinicId() async {
    final data = await Storage.getClinicData();
    final id = data?['clinic_id']?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }

  Future<String?> _currentClinicUserId() => Storage.getClinicUserId();

  Future<List<ClinicTask>> fetchTasks({
    String? assigneeId,
    TaskStatus? status,
  }) async {
    final clinicId = await _clinicId();
    if (clinicId == null) return const [];
    var query =
        _supabase.from('clinic_tasks').select(_columns).eq('clinic_id', clinicId);
    if (assigneeId != null && assigneeId.isNotEmpty) {
      query = query.eq('assignee_id', assigneeId);
    }
    if (status != null) {
      query = query.eq('status', status.value);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ClinicTask.fromMap)
        .toList(growable: false);
  }

  Future<List<ClinicTask>> fetchMyTasks({TaskStatus? status}) async {
    final me = await _currentClinicUserId();
    if (me == null || me.isEmpty) return const [];
    return fetchTasks(assigneeId: me, status: status);
  }

  Future<ClinicTask> createTask({
    required String title,
    String? description,
    required String assigneeId,
  }) async {
    final clinicId = await _clinicId();
    final me = await _currentClinicUserId();
    if (clinicId == null || me == null) {
      throw StateError('Missing clinic/user context');
    }
    final inserted = await _supabase
        .from('clinic_tasks')
        .insert({
          'clinic_id': clinicId,
          'title': title.trim(),
          'description':
              (description == null || description.trim().isEmpty)
                  ? null
                  : description.trim(),
          'assignee_id': assigneeId,
          'created_by': me,
        })
        .select(_columns)
        .single();
    return ClinicTask.fromMap(inserted);
  }

  Future<ClinicTask> updateStatus({
    required String taskId,
    required TaskStatus status,
  }) async {
    final updated = await _supabase
        .from('clinic_tasks')
        .update({'status': status.value})
        .eq('id', taskId)
        .select(_columns)
        .single();
    return ClinicTask.fromMap(updated);
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('clinic_tasks').delete().eq('id', taskId);
    } catch (e) {
      log('Error deleting task: $e');
      rethrow;
    }
  }
}
