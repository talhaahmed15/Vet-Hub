import 'package:clinic_management_app/bloc/tasks/task_form_state.dart';
import 'package:clinic_management_app/services/task_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit({required TaskService service})
      : _service = service,
        super(const TaskFormIdle());

  final TaskService _service;

  Future<void> submit({
    required String title,
    String? description,
    required String assigneeId,
  }) async {
    if (title.trim().isEmpty) {
      emit(const TaskFormFailure('Title is required.'));
      return;
    }
    if (assigneeId.trim().isEmpty) {
      emit(const TaskFormFailure('Pick an assignee.'));
      return;
    }
    emit(const TaskFormSubmitting());
    try {
      final task = await _service.createTask(
        title: title,
        description: description,
        assigneeId: assigneeId,
      );
      emit(TaskFormSuccess(task));
    } catch (e) {
      emit(TaskFormFailure(e.toString()));
    }
  }
}
