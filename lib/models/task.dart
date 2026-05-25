enum TaskStatus { todo, inProgress, done }

extension TaskStatusX on TaskStatus {
  String get value {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  static TaskStatus fromValue(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }
}

class ClinicTask {
  final String id;
  final String clinicId;
  final String title;
  final String? description;
  final String assigneeId;
  final String? assigneeName;
  final TaskStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClinicTask({
    required this.id,
    required this.clinicId,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClinicTask.fromMap(Map<String, dynamic> map) {
    final assignee = map['assignee'] as Map<String, dynamic>?;
    return ClinicTask(
      id: map['id'].toString(),
      clinicId: map['clinic_id'].toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      assigneeId: map['assignee_id'].toString(),
      assigneeName: assignee?['full_name']?.toString(),
      status: TaskStatusX.fromValue(map['status']?.toString()),
      createdBy: map['created_by'].toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }
}
