import 'package:clinic_management_app/models/task.dart';

sealed class TaskFormState {
  const TaskFormState();
}

class TaskFormIdle extends TaskFormState {
  const TaskFormIdle();
}

class TaskFormSubmitting extends TaskFormState {
  const TaskFormSubmitting();
}

class TaskFormSuccess extends TaskFormState {
  final ClinicTask task;
  const TaskFormSuccess(this.task);
}

class TaskFormFailure extends TaskFormState {
  final String message;
  const TaskFormFailure(this.message);
}
