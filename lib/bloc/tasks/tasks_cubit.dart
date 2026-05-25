import 'package:clinic_management_app/bloc/tasks/tasks_state.dart';
import 'package:clinic_management_app/models/task.dart';
import 'package:clinic_management_app/services/task_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit({required TaskService service})
      : _service = service,
        super(const TasksInitial());

  final TaskService _service;

  String? _assigneeFilter;
  TaskStatus? _statusFilter;
  bool _myTasksOnly = false;

  void configureForEmployee() {
    _myTasksOnly = true;
  }

  Future<void> load() async {
    emit(const TasksLoading());
    try {
      final tasks = _myTasksOnly
          ? await _service.fetchMyTasks(status: _statusFilter)
          : await _service.fetchTasks(
              assigneeId: _assigneeFilter,
              status: _statusFilter,
            );
      emit(TasksLoaded(
        tasks: tasks,
        assigneeFilter: _assigneeFilter,
        statusFilter: _statusFilter,
      ));
    } catch (e) {
      emit(TasksFailure(e.toString()));
    }
  }

  Future<void> setAssigneeFilter(String? assigneeId) async {
    _assigneeFilter = assigneeId;
    await load();
  }

  Future<void> setStatusFilter(TaskStatus? status) async {
    _statusFilter = status;
    await load();
  }

  Future<void> changeStatus(String taskId, TaskStatus status) async {
    final current = state;
    if (current is! TasksLoaded) {
      return;
    }
    final optimistic = current.tasks.map((t) {
      if (t.id != taskId) return t;
      return ClinicTask(
        id: t.id,
        clinicId: t.clinicId,
        title: t.title,
        description: t.description,
        assigneeId: t.assigneeId,
        assigneeName: t.assigneeName,
        status: status,
        createdBy: t.createdBy,
        createdAt: t.createdAt,
        updatedAt: DateTime.now(),
      );
    }).toList();
    emit(current.copyWith(tasks: optimistic));
    try {
      await _service.updateStatus(taskId: taskId, status: status);
    } catch (e) {
      emit(current);
      emit(TasksFailure(e.toString()));
      emit(current);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final current = state;
    try {
      await _service.deleteTask(taskId);
      if (current is TasksLoaded) {
        emit(current.copyWith(
          tasks: current.tasks.where((t) => t.id != taskId).toList(),
        ));
      } else {
        await load();
      }
    } catch (e) {
      emit(TasksFailure(e.toString()));
      if (current is TasksLoaded) emit(current);
    }
  }
}
