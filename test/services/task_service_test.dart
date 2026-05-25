import 'package:clinic_management_app/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskStatusX.fromValue', () {
    test('parses todo', () {
      expect(TaskStatusX.fromValue('todo'), TaskStatus.todo);
    });
    test('parses in_progress', () {
      expect(TaskStatusX.fromValue('in_progress'), TaskStatus.inProgress);
    });
    test('parses done', () {
      expect(TaskStatusX.fromValue('done'), TaskStatus.done);
    });
    test('defaults to todo for null/unknown', () {
      expect(TaskStatusX.fromValue(null), TaskStatus.todo);
      expect(TaskStatusX.fromValue('wat'), TaskStatus.todo);
    });
  });

  group('ClinicTask.fromMap', () {
    test('reads assignee name from joined row', () {
      final map = {
        'id': 'a',
        'clinic_id': 'c',
        'title': 'feed',
        'description': null,
        'assignee_id': 'u',
        'status': 'in_progress',
        'created_by': 'o',
        'created_at': '2026-05-25T10:00:00Z',
        'updated_at': '2026-05-25T10:00:00Z',
        'assignee': {'full_name': 'Jane'},
      };
      final task = ClinicTask.fromMap(map);
      expect(task.title, 'feed');
      expect(task.status, TaskStatus.inProgress);
      expect(task.assigneeName, 'Jane');
    });
  });
}
