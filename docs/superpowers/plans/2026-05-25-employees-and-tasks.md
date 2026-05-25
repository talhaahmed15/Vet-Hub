# Employees & Tasks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let owners/admins create clinic employees (username + password + role) and assign each employee minimal tasks. Non-admin staff get a restricted two-tab home (My Tasks + Profile).

**Architecture:** New `clinic_tasks` Postgres table with clinic-scoped RLS. The existing `create-clinic-user` Edge Function is reused for employee creation — no new function needed. Flutter side gets a new `TaskService`, two cubits, a Tasks tab inside the existing `ClinicRootScreen` for owner/admin, and a new `EmployeeHomeScreen` shell selected at post-login routing time based on role.

**Tech Stack:** Flutter, `flutter_bloc`, Supabase (Postgres + Auth + Edge Functions), Dart 3, existing app widgets (`CustomTextField`, `CustomDropdownField`, `PrimaryButton`, `CustomAppBar`).

---

## Spec deviation note (read first)

The spec proposed a new Edge Function `create-clinic-employee`. While reading the codebase I found `supabase/functions/create-clinic-user/index.ts` already does:

- Verifies clinic exists (by `clinic_code`)
- Rejects duplicate username within clinic
- Calls `auth.admin.createUser` (service-role)
- Inserts `clinic_users` row with role
- Rolls back the auth user on `clinic_users` insert failure

This is precisely what the spec asked for. **We reuse it instead of writing a new one.** The only adjustment: in the current code, new clinic_users are inserted with `account_status: "under_review"`. For employees created directly by an owner/admin, we want `account_status: "active"` so they can log in immediately. We add an optional `account_status` field to the function payload (defaults to existing `under_review` behavior to avoid changing the existing signup flow).

The spec also said "email + password." The existing flow uses **username + password** with a synthesized auth email. We keep username — it matches what's already shipping and what other screens in the auth flow expect.

---

## File Structure

**New files:**

- `supabase/migrations/20260525120000_create_clinic_tasks.sql` — table + indexes + RLS + helper fn
- `lib/models/task.dart` — `ClinicTask` data class + `TaskStatus` enum
- `lib/services/task_service.dart` — Supabase CRUD
- `lib/bloc/tasks/tasks_state.dart` — sealed states for list cubit
- `lib/bloc/tasks/tasks_cubit.dart` — list + filters
- `lib/bloc/tasks/task_form_state.dart` — sealed states for form cubit
- `lib/bloc/tasks/task_form_cubit.dart` — create-task form
- `lib/screens/clinic/tasks/tasks_screen.dart` — owner/admin global Tasks tab
- `lib/screens/clinic/tasks/task_form_sheet.dart` — bottom sheet to create a task
- `lib/screens/clinic/tasks/widgets/task_card.dart` — single task row widget
- `lib/screens/clinic/settings_module/add_member_sheet.dart` — bottom sheet to create a clinic user (calls `create-clinic-user` function)
- `lib/screens/employee/employee_home_screen.dart` — two-tab shell for non-admin roles
- `lib/screens/employee/my_tasks_screen.dart` — assignee=me task list with status changes
- `lib/screens/employee/employee_profile_screen.dart` — name/email/role read-only + log-out
- `test/services/task_service_test.dart` — unit tests for service query construction
- `test/bloc/tasks_cubit_test.dart` — bloc state transitions

**Modified files:**

- `supabase/functions/create-clinic-user/index.ts` — accept optional `account_status` in payload
- `lib/services/clinic_member_service.dart` — add `createMember(...)` method calling the Edge Function
- `lib/screens/clinic/settings_module/clinic_members_screen.dart` — add a "+" FAB when `canManage`, opens `AddMemberSheet`
- `lib/screens/clinic/clinic_root.dart` — add a Tasks nav item
- `lib/screens/auth/login_screen.dart` — branch on role at `_routeByStatus` ("active") to pick `ClinicRootScreen` vs `EmployeeHomeScreen`
- `lib/main.dart` — register new repos/cubits (`TaskService`, `TasksCubit`, `TaskFormCubit`)
- `pubspec.yaml` — only if `bloc_test` is not present; add to dev_deps for cubit tests

---

## Conventions

- Match existing patterns: BLoC cubits emit sealed states (`...Initial`, `...Loading`, `...Success`, `...Failure`), like `LoggedClinicCubit`.
- Reuse `CustomTextField`, `CustomDropdownField`, `PrimaryButton`, `CustomAppBar`, `StatusChip`, `AppToast.success/error`, `Spacing` extensions (`12.height`, `8.width`).
- Status strings (`'todo' | 'in_progress' | 'done'`) live in the DB; `TaskStatus` enum mirrors them with a `value` getter.
- Date format: `timestamptz`, stored UTC, displayed via `DateFormat.yMMMd().add_jm()` (already used in app — search for examples).

---

## Task 1: Database migration for clinic_tasks

**Files:**
- Create: `supabase/migrations/20260525120000_create_clinic_tasks.sql`

- [ ] **Step 1: Write the migration**

```sql
-- Helper to read the calling user's role within a given clinic.
create or replace function public.current_clinic_user_role(target_clinic_id uuid)
returns text
language sql
security definer
stable
as $$
  select role
  from public.clinic_users
  where clinic_id = target_clinic_id
    and auth_user_id = auth.uid()
  limit 1;
$$;

revoke all on function public.current_clinic_user_role(uuid) from public;
grant execute on function public.current_clinic_user_role(uuid) to authenticated;

create table if not exists public.clinic_tasks (
  id           uuid primary key default gen_random_uuid(),
  clinic_id    uuid not null references public.clinics(clinic_id) on delete cascade,
  title        text not null check (char_length(title) between 1 and 200),
  description  text,
  assignee_id  uuid not null references public.clinic_users(id) on delete cascade,
  status       text not null default 'todo'
               check (status in ('todo','in_progress','done')),
  created_by   uuid not null references public.clinic_users(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists clinic_tasks_clinic_status_idx
  on public.clinic_tasks(clinic_id, status);
create index if not exists clinic_tasks_assignee_status_idx
  on public.clinic_tasks(assignee_id, status);

-- Auto-update updated_at on row updates.
create or replace function public.touch_clinic_tasks_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists clinic_tasks_touch_updated_at on public.clinic_tasks;
create trigger clinic_tasks_touch_updated_at
  before update on public.clinic_tasks
  for each row execute function public.touch_clinic_tasks_updated_at();

alter table public.clinic_tasks enable row level security;

-- SELECT: any user in the same clinic can read.
create policy clinic_tasks_select on public.clinic_tasks
  for select to authenticated
  using (
    exists (
      select 1 from public.clinic_users cu
      where cu.clinic_id = clinic_tasks.clinic_id
        and cu.auth_user_id = auth.uid()
    )
  );

-- INSERT: only owner or admin in that clinic.
create policy clinic_tasks_insert on public.clinic_tasks
  for insert to authenticated
  with check (
    public.current_clinic_user_role(clinic_id) in ('owner','admin')
  );

-- UPDATE: owner/admin of the clinic OR the assignee themselves.
create policy clinic_tasks_update on public.clinic_tasks
  for update to authenticated
  using (
    public.current_clinic_user_role(clinic_id) in ('owner','admin')
    or exists (
      select 1 from public.clinic_users cu
      where cu.id = clinic_tasks.assignee_id
        and cu.auth_user_id = auth.uid()
    )
  )
  with check (
    public.current_clinic_user_role(clinic_id) in ('owner','admin')
    or exists (
      select 1 from public.clinic_users cu
      where cu.id = clinic_tasks.assignee_id
        and cu.auth_user_id = auth.uid()
    )
  );

-- DELETE: owner/admin only.
create policy clinic_tasks_delete on public.clinic_tasks
  for delete to authenticated
  using (
    public.current_clinic_user_role(clinic_id) in ('owner','admin')
  );
```

- [ ] **Step 2: Apply locally**

Run: `npx supabase db push` (or `supabase migration up` if using local CLI)
Expected: migration applied, no errors.

- [ ] **Step 3: Smoke-test RLS in Supabase SQL editor (or psql)**

```sql
-- as an authenticated owner, insert should succeed:
insert into clinic_tasks (clinic_id, title, assignee_id, created_by)
values ('<existing-clinic-uuid>', 'Test', '<assignee-clinic-user-uuid>', '<owner-clinic-user-uuid>');

-- as an assignee, updating status should succeed:
update clinic_tasks set status = 'in_progress' where id = '<the-id-above>';

-- as an assistant who is NOT the assignee, update should be denied (returns 0 rows updated).
```

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260525120000_create_clinic_tasks.sql
git commit -m "feat(db): add clinic_tasks table with RLS"
```

---

## Task 2: Extend create-clinic-user Edge Function to accept account_status

**Files:**
- Modify: `supabase/functions/create-clinic-user/index.ts`

- [ ] **Step 1: Update the Zod schema**

In `ClinicUserSchema`, add the optional `account_status` field:

```ts
const ClinicUserSchema = z
  .object({
    clinic_code: z.string().length(5),
    full_name: z.string().min(3),
    username: z.string().min(3),
    password: z.string().min(8).optional(),
    role: RoleSchema,
    phone: z.string().min(5),
    auth_email: z.string().email().optional(),
    auth_user_id: z.string().uuid().optional(),
    account_status: z.enum(['active', 'under_review', 'blocked']).optional(),
  })
  .refine((data) => data.auth_user_id || data.password, {
    message: "Password or auth_user_id is required",
  });
```

- [ ] **Step 2: Use the value when inserting**

Find the insert block (around line 198) and change `account_status` to use the payload value when provided:

```ts
const { data: profile, error: profileError } = await supabase
  .from("clinic_users")
  .insert({
    clinic_id: clinic.clinic_id,
    full_name: payload.full_name,
    username: payload.username,
    phone: payload.phone,
    auth_email: payload.auth_email ??
      `${payload.username.trim().toLowerCase()}@${payload.clinic_code}.vet-hub.local`,
    account_status: payload.account_status ?? "under_review",
    role: payload.role,
    auth_user_id: authUserId,
  })
  .select()
  .single();
```

- [ ] **Step 3: Deploy the function**

Run: `npx supabase functions deploy create-clinic-user`
Expected: "Deployed Function create-clinic-user".

- [ ] **Step 4: Manual test**

Call the function from `curl` or Supabase Studio with a payload including `"account_status": "active"`. Confirm the inserted row has `account_status = 'active'`.

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/create-clinic-user/index.ts
git commit -m "feat(fn): accept optional account_status in create-clinic-user"
```

---

## Task 3: ClinicTask model and TaskStatus enum

**Files:**
- Create: `lib/models/task.dart`

- [ ] **Step 1: Write the model**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/models/task.dart
git commit -m "feat: add ClinicTask model and TaskStatus enum"
```

---

## Task 4: TaskService

**Files:**
- Create: `lib/services/task_service.dart`
- Create: `test/services/task_service_test.dart`

- [ ] **Step 1: Write the service**

```dart
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
```

- [ ] **Step 2: Wire TaskService as a RepositoryProvider in main.dart**

In `lib/main.dart`, add to the providers list after the existing services:

```dart
final taskRepository = TaskService();
// inside MultiRepositoryProvider providers:
RepositoryProvider<TaskService>.value(value: taskRepository),
```

And add the import at the top: `import 'package:clinic_management_app/services/task_service.dart';`

- [ ] **Step 3: Add unit test**

Project does not currently have a `test/` folder; create it.

```dart
// test/services/task_service_test.dart
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
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/services/task_service_test.dart`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/task_service.dart test/services/task_service_test.dart lib/main.dart
git commit -m "feat: add TaskService and ClinicTask parsing tests"
```

---

## Task 5: TasksCubit (list + filters)

**Files:**
- Create: `lib/bloc/tasks/tasks_state.dart`
- Create: `lib/bloc/tasks/tasks_cubit.dart`

- [ ] **Step 1: Write the state**

```dart
// tasks_state.dart
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
```

- [ ] **Step 2: Write the cubit**

```dart
// tasks_cubit.dart
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
  // When true, the cubit only loads tasks for the current clinic user.
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
    // Optimistic update.
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
      // Revert on failure.
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
```

- [ ] **Step 3: Commit**

```bash
git add lib/bloc/tasks/tasks_state.dart lib/bloc/tasks/tasks_cubit.dart
git commit -m "feat(bloc): TasksCubit with filters and optimistic status changes"
```

---

## Task 6: TaskFormCubit (create task)

**Files:**
- Create: `lib/bloc/tasks/task_form_state.dart`
- Create: `lib/bloc/tasks/task_form_cubit.dart`

- [ ] **Step 1: Write state + cubit**

```dart
// task_form_state.dart
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
```

```dart
// task_form_cubit.dart
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/bloc/tasks/task_form_state.dart lib/bloc/tasks/task_form_cubit.dart
git commit -m "feat(bloc): TaskFormCubit for create-task flow"
```

---

## Task 7: Tasks screen + task form sheet (owner/admin)

**Files:**
- Create: `lib/screens/clinic/tasks/widgets/task_card.dart`
- Create: `lib/screens/clinic/tasks/task_form_sheet.dart`
- Create: `lib/screens/clinic/tasks/tasks_screen.dart`

- [ ] **Step 1: Task card widget**

```dart
// task_card.dart
import 'package:clinic_management_app/models/task.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final ClinicTask task;
  final bool showAssignee;
  final ValueChanged<TaskStatus> onStatusChange;
  final VoidCallback? onDelete; // null = no delete button shown

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChange,
    this.showAssignee = true,
    this.onDelete,
  });

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return Colors.orange;
      case TaskStatus.inProgress:
        return AppColors.primary;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  Future<void> _pickStatus(BuildContext context) async {
    final picked = await showModalBottomSheet<TaskStatus>(
      context: context,
      backgroundColor: AppColors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskStatus.values
              .map((s) => ListTile(
                    leading: Icon(Icons.circle, color: _statusColor(s), size: 12),
                    title: Text(s.label, style: AppFonts.regular()),
                    onTap: () => Navigator.of(ctx).pop(s),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null && picked != task.status) {
      onStatusChange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(task.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppFonts.semiBold(fontSize: 14)),
                if (task.description != null &&
                    task.description!.trim().isNotEmpty) ...[
                  4.height,
                  Text(
                    task.description!,
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
                if (showAssignee &&
                    task.assigneeName != null &&
                    task.assigneeName!.trim().isNotEmpty) ...[
                  6.height,
                  Text(
                    'Assigned to ${task.assigneeName}',
                    style: AppFonts.regular(
                      fontSize: 11,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          8.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _pickStatus(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    task.status.label,
                    style: AppFonts.semiBold(fontSize: 11, color: color),
                  ),
                ),
              ),
              if (onDelete != null) ...[
                4.height,
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Task form sheet**

```dart
// task_form_sheet.dart
import 'package:clinic_management_app/bloc/tasks/task_form_cubit.dart';
import 'package:clinic_management_app/bloc/tasks/task_form_state.dart';
import 'package:clinic_management_app/models/clinic_member.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/services/task_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskFormSheet extends StatefulWidget {
  /// Returns true if a task was created.
  static Future<bool> show(BuildContext context, TaskService taskService) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider(
        create: (_) => TaskFormCubit(service: taskService),
        child: const TaskFormSheet._(),
      ),
    );
    return result == true;
  }

  const TaskFormSheet._();

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _memberService = ClinicMemberService();

  Future<List<ClinicMember>>? _members;
  String? _assigneeId;

  @override
  void initState() {
    super.initState();
    _members = _memberService.fetchMembers();
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: BlocConsumer<TaskFormCubit, TaskFormState>(
        listener: (context, state) {
          if (state is TaskFormSuccess) {
            AppToast.success(context, 'Task created.');
            Navigator.of(context).pop(true);
          } else if (state is TaskFormFailure) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          final submitting = state is TaskFormSubmitting;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Task', style: AppFonts.semiBold(fontSize: 16)),
              12.height,
              Text('Title', style: AppFonts.semiBold(fontSize: 12)),
              6.height,
              CustomTextField(controller: _titleCtl, hintText: 'Title'),
              12.height,
              Text('Description', style: AppFonts.semiBold(fontSize: 12)),
              6.height,
              CustomTextField(
                controller: _descCtl,
                hintText: 'Optional details',
                maxLines: 3,
              ),
              12.height,
              Text('Assignee', style: AppFonts.semiBold(fontSize: 12)),
              6.height,
              FutureBuilder<List<ClinicMember>>(
                future: _members,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  final members = snap.data ?? const <ClinicMember>[];
                  return CustomDropdownField<String>(
                    items: members.map((m) => m.id).toList(),
                    value: _assigneeId,
                    labelBuilder: (id) {
                      final m = members.firstWhere(
                        (x) => x.id == id,
                        orElse: () => ClinicMember(
                          id: id,
                          fullName: id,
                          role: '',
                          accountStatus: '',
                        ),
                      );
                      return '${m.fullName} • ${m.roleLabel}';
                    },
                    hintText: 'Choose a member',
                    onChanged: (v) => setState(() => _assigneeId = v),
                  );
                },
              ),
              16.height,
              PrimaryButton(
                text: submitting ? 'Saving…' : 'Create Task',
                onPressed: submitting
                    ? null
                    : () => context.read<TaskFormCubit>().submit(
                          title: _titleCtl.text,
                          description: _descCtl.text,
                          assigneeId: _assigneeId ?? '',
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

> If `CustomTextField` does not currently accept `maxLines`, omit that argument and let the field be single-line. Verify by opening `lib/widgets/custom_textfield.dart` before editing.

- [ ] **Step 3: Tasks screen**

```dart
// tasks_screen.dart
import 'package:clinic_management_app/bloc/tasks/tasks_cubit.dart';
import 'package:clinic_management_app/bloc/tasks/tasks_state.dart';
import 'package:clinic_management_app/models/clinic_member.dart';
import 'package:clinic_management_app/models/task.dart';
import 'package:clinic_management_app/screens/clinic/tasks/task_form_sheet.dart';
import 'package:clinic_management_app/screens/clinic/tasks/widgets/task_card.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/services/task_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Future<List<ClinicMember>> _members;

  @override
  void initState() {
    super.initState();
    _members = ClinicMemberService().fetchMembers();
    // Kick off the first load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksCubit>().load();
    });
  }

  Future<void> _create() async {
    final created = await TaskFormSheet.show(
      context,
      context.read<TaskService>(),
    );
    if (created && mounted) {
      context.read<TasksCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Tasks'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _create,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: PageContent(
        maxWidth: 800,
        fillHeight: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FutureBuilder<List<ClinicMember>>(
                future: _members,
                builder: (ctx, snap) {
                  final members = snap.data ?? const <ClinicMember>[];
                  return Row(
                    children: [
                      Expanded(
                        child: CustomDropdownField<String?>(
                          items: <String?>[null, ...members.map((m) => m.id)],
                          value: (context.watch<TasksCubit>().state
                                  is TasksLoaded)
                              ? (context.watch<TasksCubit>().state
                                      as TasksLoaded)
                                  .assigneeFilter
                              : null,
                          labelBuilder: (id) {
                            if (id == null) return 'All members';
                            final m = members.firstWhere(
                              (x) => x.id == id,
                              orElse: () => ClinicMember(
                                id: id,
                                fullName: id,
                                role: '',
                                accountStatus: '',
                              ),
                            );
                            return m.fullName;
                          },
                          hintText: 'Filter by member',
                          onChanged: (v) =>
                              context.read<TasksCubit>().setAssigneeFilter(v),
                        ),
                      ),
                      8.width,
                      Expanded(
                        child: CustomDropdownField<TaskStatus?>(
                          items: const <TaskStatus?>[
                            null,
                            TaskStatus.todo,
                            TaskStatus.inProgress,
                            TaskStatus.done,
                          ],
                          value: (context.watch<TasksCubit>().state
                                  is TasksLoaded)
                              ? (context.watch<TasksCubit>().state
                                      as TasksLoaded)
                                  .statusFilter
                              : null,
                          labelBuilder: (s) => s == null ? 'All statuses' : s.label,
                          hintText: 'Filter by status',
                          onChanged: (v) =>
                              context.read<TasksCubit>().setStatusFilter(v),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            12.height,
            Expanded(
              child: BlocBuilder<TasksCubit, TasksState>(
                builder: (context, state) {
                  if (state is TasksLoading || state is TasksInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is TasksFailure) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message, style: AppFonts.regular()),
                          12.height,
                          ElevatedButton(
                            onPressed: () =>
                                context.read<TasksCubit>().load(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final tasks = (state as TasksLoaded).tasks;
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No tasks yet. Tap + to add one.',
                        style: AppFonts.regular(color: AppColors.grey),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => 12.height,
                    itemBuilder: (ctx, i) {
                      final task = tasks[i];
                      return TaskCard(
                        task: task,
                        showAssignee: true,
                        onStatusChange: (s) => context
                            .read<TasksCubit>()
                            .changeStatus(task.id, s),
                        onDelete: () =>
                            context.read<TasksCubit>().deleteTask(task.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/clinic/tasks
git commit -m "feat(ui): tasks list and create-task sheet for owner/admin"
```

---

## Task 8: Add Tasks tab to ClinicRootScreen

**Files:**
- Modify: `lib/screens/clinic/clinic_root.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Register a TasksCubit at app root in main.dart**

Add the import and BLoC provider (alongside the other BlocProviders):

```dart
import 'package:clinic_management_app/bloc/tasks/tasks_cubit.dart';
import 'package:clinic_management_app/services/task_service.dart';

// inside MultiBlocProvider providers list:
BlocProvider(
  create: (context) => TasksCubit(service: context.read<TaskService>()),
),
```

- [ ] **Step 2: Insert "Tasks" into the nav items in clinic_root.dart**

Replace the `_navItems` and `_pages` lists in `_ClinicRootScreenState`:

```dart
static const List<ClinicNavItem> _navItems = [
  ClinicNavItem(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Home',
  ),
  ClinicNavItem(
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
    label: 'Appointments',
  ),
  ClinicNavItem(
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
    label: 'Tasks',
  ),
  ClinicNavItem(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: 'Inventory',
  ),
  ClinicNavItem(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: 'Invoices',
  ),
  ClinicNavItem(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

final List<Widget> _pages = const [
  ClinicDashboardScreen(),
  RecentAppointmentsScreen(),
  TasksScreen(),
  InventoryListScreen(),
  PatientsScreen(),
  SettingsScreen(),
];
```

And add the import: `import 'package:clinic_management_app/screens/clinic/tasks/tasks_screen.dart';`

- [ ] **Step 3: Manual test**

Run: `flutter run`
Steps:
1. Log in as owner.
2. Confirm the bottom nav has six tabs and "Tasks" appears between Appointments and Inventory.
3. Open Tasks tab → empty state shows.
4. Tap "+" → create a task with yourself as assignee → list shows it.
5. Tap the status chip → change to "In Progress" → status updates.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/clinic/clinic_root.dart lib/main.dart
git commit -m "feat(ui): add Tasks tab to clinic shell"
```

---

## Task 9: ClinicMemberService.createMember + AddMemberSheet

**Files:**
- Modify: `lib/services/clinic_member_service.dart`
- Create: `lib/screens/clinic/settings_module/add_member_sheet.dart`
- Modify: `lib/screens/clinic/settings_module/clinic_members_screen.dart`

- [ ] **Step 1: Add createMember to the service**

Append to the existing class:

```dart
Future<void> createMember({
  required String fullName,
  required String username,
  required String password,
  required String phone,
  required String role,
}) async {
  final clinic = await Storage.getClinicData();
  final clinicCode = clinic?['clinic_code']?.toString();
  if (clinicCode == null || clinicCode.isEmpty) {
    throw StateError('Missing clinic_code in local storage');
  }
  try {
    final response = await _supabase.functions.invoke(
      'create-clinic-user',
      body: {
        'clinic_code': clinicCode,
        'full_name': fullName.trim(),
        'username': username.trim(),
        'password': password,
        'phone': phone.trim(),
        'role': role,
        'account_status': 'active',
      },
    );
    final data = response.data;
    if (data is Map && data['ok'] != true) {
      throw Exception(data['error']?.toString() ?? 'Failed to create user');
    }
  } catch (e) {
    log('Error creating clinic member: $e');
    rethrow;
  }
}
```

- [ ] **Step 2: Add the AddMemberSheet**

```dart
// add_member_sheet.dart
import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class AddMemberSheet extends StatefulWidget {
  /// Returns true if a member was created.
  static Future<bool> show(BuildContext context) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddMemberSheet._(),
    );
    return res == true;
  }

  const AddMemberSheet._();

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  String _role = ClinicRole.assistant.value;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 3) {
      AppToast.error(context, 'Full name must be at least 3 characters.');
      return;
    }
    if (_username.text.trim().length < 3) {
      AppToast.error(context, 'Username must be at least 3 characters.');
      return;
    }
    if (_password.text.length < 8) {
      AppToast.error(context, 'Password must be at least 8 characters.');
      return;
    }
    if (_phone.text.trim().length < 5) {
      AppToast.error(context, 'Phone is required.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ClinicMemberService().createMember(
        fullName: _name.text,
        username: _username.text,
        password: _password.text,
        phone: _phone.text,
        role: _role,
      );
      if (!mounted) return;
      AppToast.success(context, 'Member created.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Member', style: AppFonts.semiBold(fontSize: 16)),
          12.height,
          Text('Full Name', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomTextField(controller: _name, hintText: 'Jane Doe'),
          12.height,
          Text('Username', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomTextField(controller: _username, hintText: 'jane'),
          12.height,
          Text('Password', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomTextField(
            controller: _password,
            hintText: 'Min 8 characters',
            obscureText: true,
          ),
          12.height,
          Text('Phone', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomTextField(
            controller: _phone,
            hintText: '+1 555 000 0000',
            keyboardType: TextInputType.phone,
          ),
          12.height,
          Text('Role', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomDropdownField<String>(
            items: ClinicRole.values
                .where((r) => r != ClinicRole.owner)
                .map((r) => r.value)
                .toList(),
            value: _role,
            labelBuilder: (v) {
              final r = ClinicRole.values.firstWhere(
                (e) => e.value == v,
                orElse: () => ClinicRole.assistant,
              );
              return r.label;
            },
            hintText: 'Select role',
            onChanged: (v) {
              if (v != null) setState(() => _role = v);
            },
          ),
          16.height,
          PrimaryButton(
            text: _submitting ? 'Creating…' : 'Create Member',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
```

> Before editing, open `lib/widgets/custom_textfield.dart` and confirm `obscureText`/`keyboardType` are valid parameters; if they have different names, adapt the call sites.

- [ ] **Step 3: Wire the sheet from ClinicMembersScreen**

In `clinic_members_screen.dart`:

1. Add an import: `import 'package:clinic_management_app/screens/clinic/settings_module/add_member_sheet.dart';`
2. Add a `floatingActionButton` to the `Scaffold` returned by `build`, visible only when `widget.canManage`:

```dart
floatingActionButton: widget.canManage
    ? FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final created = await AddMemberSheet.show(context);
          if (created) _reload();
        },
        child: const Icon(Icons.add, color: Colors.white),
      )
    : null,
```

- [ ] **Step 4: Manual test**

Run: `flutter run`. Log in as owner. Open Settings → User Management. Tap "+". Fill the form. Submit. Confirm new member appears in the list with status "Active." Log out, log in as the new user — login should succeed (Task 12 covers what happens after).

- [ ] **Step 5: Commit**

```bash
git add lib/services/clinic_member_service.dart \
        lib/screens/clinic/settings_module/add_member_sheet.dart \
        lib/screens/clinic/settings_module/clinic_members_screen.dart
git commit -m "feat(ui): owner/admin can create clinic members"
```

---

## Task 10: Employee home — My Tasks tab

**Files:**
- Create: `lib/screens/employee/my_tasks_screen.dart`

- [ ] **Step 1: Build the screen**

```dart
import 'package:clinic_management_app/bloc/tasks/tasks_cubit.dart';
import 'package:clinic_management_app/bloc/tasks/tasks_state.dart';
import 'package:clinic_management_app/screens/clinic/tasks/widgets/task_card.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<TasksCubit>();
    cubit.configureForEmployee();
    WidgetsBinding.instance.addPostFrameCallback((_) => cubit.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'My Tasks'),
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading || state is TasksInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TasksFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, style: AppFonts.regular()),
                  12.height,
                  ElevatedButton(
                    onPressed: () => context.read<TasksCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final tasks = (state as TasksLoaded).tasks;
          if (tasks.isEmpty) {
            return Center(
              child: Text(
                'You have no tasks.',
                style: AppFonts.regular(color: AppColors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<TasksCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => 12.height,
              itemBuilder: (ctx, i) {
                final task = tasks[i];
                return TaskCard(
                  task: task,
                  showAssignee: false,
                  onStatusChange: (s) =>
                      context.read<TasksCubit>().changeStatus(task.id, s),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/employee/my_tasks_screen.dart
git commit -m "feat(ui): employee My Tasks screen"
```

---

## Task 11: Employee home — Profile tab + shell

**Files:**
- Create: `lib/screens/employee/employee_profile_screen.dart`
- Create: `lib/screens/employee/employee_home_screen.dart`

- [ ] **Step 1: Profile screen**

```dart
// employee_profile_screen.dart
import 'package:clinic_management_app/models/clinic_member.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/screens/auth/app_start_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  late Future<ClinicMember?> _me;

  @override
  void initState() {
    super.initState();
    _me = ClinicMemberService().fetchCurrentMember();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    await Storage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AppStartScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Profile'),
      body: FutureBuilder<ClinicMember?>(
        future: _me,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final m = snap.data;
          if (m == null) {
            return Center(
              child: Text('Could not load profile.', style: AppFonts.regular()),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: 'Name', value: m.fullName),
                12.height,
                _Row(label: 'Role', value: m.roleLabel),
                12.height,
                _Row(label: 'Status', value: m.statusLabel),
                if (m.phone != null && m.phone!.trim().isNotEmpty) ...[
                  12.height,
                  _Row(label: 'Phone', value: m.phone!),
                ],
                const Spacer(),
                PrimaryButton(text: 'Log out', onPressed: _logout),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppFonts.semiBold(fontSize: 12)),
        ),
        Expanded(child: Text(value, style: AppFonts.regular(fontSize: 13))),
      ],
    );
  }
}
```

> If `Storage.clear()` does not exist, replace with whatever the existing logout flow uses (search the auth screens for the precedent — likely setting per-key removes).

- [ ] **Step 2: Two-tab shell**

```dart
// employee_home_screen.dart
import 'package:clinic_management_app/screens/employee/employee_profile_screen.dart';
import 'package:clinic_management_app/screens/employee/my_tasks_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:flutter/material.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _index = 0;

  static const _pages = <Widget>[
    MyTasksScreen(),
    EmployeeProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'My Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/employee
git commit -m "feat(ui): employee two-tab home (My Tasks + Profile)"
```

---

## Task 12: Role-based routing after login

**Files:**
- Modify: `lib/screens/auth/login_screen.dart`

- [ ] **Step 1: Branch on role at the "active" path**

Open `lib/screens/auth/login_screen.dart`. Find `_routeByStatus` (line 96). Replace the "active" branch:

```dart
void _routeByStatus(String status) async {
  final normalized = status.trim().toLowerCase();
  if (normalized == 'active') {
    final member = await ClinicMemberService().fetchCurrentMember();
    if (!mounted) return;
    final role = (member?.role ?? '').trim().toLowerCase();
    final isAdmin = role == 'owner' || role == 'admin';
    NavigatorHelper.replace(
      context,
      isAdmin ? const ClinicRootScreen() : const EmployeeHomeScreen(),
    );
  } else if (normalized == 'blocked') {
    // existing code...
  }
  // existing else...
}
```

Add imports:

```dart
import 'package:clinic_management_app/screens/employee/employee_home_screen.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
```

- [ ] **Step 2: Manual test — happy path**

Run: `flutter run`.
1. Log in as owner → lands on `ClinicRootScreen` with six tabs including Tasks.
2. Owner creates a "vet" or "assistant" member and assigns them a task.
3. Log out. Log in as that employee → lands on `EmployeeHomeScreen` with two tabs.
4. My Tasks shows the assigned task. Profile shows their name + role.
5. Tap status chip → change to In Progress → confirm change persists by pulling-to-refresh.

- [ ] **Step 3: Manual test — RLS sanity**

Still logged in as the employee, open the in-app Supabase logs or attempt a debug query to ensure they cannot read other employees' tasks via direct query. (Not strictly required if Task 1 step 3 SQL checks already passed, but worth a sanity check.)

- [ ] **Step 4: Commit**

```bash
git add lib/screens/auth/login_screen.dart
git commit -m "feat(auth): route to employee home for non-admin roles"
```

---

## Task 13: Final integration pass

- [ ] **Step 1: Static analysis**

Run: `flutter analyze`
Expected: no new errors. Address any issues from the new files.

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 3: End-to-end manual check (two-device or two-account)**

1. Owner account on Device A.
2. Owner creates "Bob" (vet, active).
3. Owner creates a task "Vaccinate Rex" assigned to Bob.
4. Bob logs in on Device B → sees one task in "My Tasks".
5. Bob taps status → "Done". On Device A, owner pull-refreshes Tasks tab → sees Done status.
6. Owner deletes the task → it disappears from Bob's list (after refresh).

- [ ] **Step 4: Commit any cleanup**

```bash
git add -A
git commit -m "chore: cleanup after employees-and-tasks feature"
```

---

## Self-review notes (resolved)

- **Spec coverage:** owner/admin create employees (Tasks 2 & 9), tasks CRUD with RLS (Tasks 1, 4, 5, 6, 7), owner/admin Tasks tab (Task 8), employee two-tab home (Tasks 10, 11), role routing (Task 12). All spec requirements have tasks.
- **Edge Function deviation** documented up front; reuses existing function with one small additive change.
- **Type consistency:** `TaskStatus` and `TaskStatusX.value` consistent across model/service/cubit/UI; `TasksCubit.changeStatus`, `setStatusFilter`, `setAssigneeFilter` referenced identically across Tasks 5/7/10.
- **Placeholders:** none — every step has the exact code or command.
- **Widget-call caveats:** the plan flags two places where existing widget signatures should be confirmed before editing (`CustomTextField.maxLines`, `Storage.clear()`). These are explicitly called out as verify-before-changing rather than left ambiguous.
