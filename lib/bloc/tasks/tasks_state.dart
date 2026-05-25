import 'package:clinic_management_app/models/task.dart';

sealed class TasksState {
  const TasksState();
}

class TasksInitial extends TasksState {
  const TasksInitial();
}

class TasksLoading extends TasksState {
  const TasksLoading();
}

class TasksLoaded extends TasksState {
  final List<ClinicTask> tasks;
  final String? assigneeFilter; // clinic_users.id, null = all
  final TaskStatus? statusFilter;
  const TasksLoaded({
    required this.tasks,
    this.assigneeFilter,
    this.statusFilter,
  });

  TasksLoaded copyWith({
    List<ClinicTask>? tasks,
    Object? assigneeFilter = _unset,
    Object? statusFilter = _unset,
  }) {
    return TasksLoaded(
      tasks: tasks ?? this.tasks,
      assigneeFilter: assigneeFilter == _unset
          ? this.assigneeFilter
          : assigneeFilter as String?,
      statusFilter: statusFilter == _unset
          ? this.statusFilter
          : statusFilter as TaskStatus?,
    );
  }
}

class TasksFailure extends TasksState {
  final String message;
  const TasksFailure(this.message);
}

const _unset = Object();
