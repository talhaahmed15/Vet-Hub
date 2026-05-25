# Employees & Tasks — Design

**Date:** 2026-05-25
**Status:** Approved for planning

## Goal

Allow a clinic owner/admin to create staff user accounts directly (name, email, password, role) and assign each employee tasks. Non-admin employees get a restricted UI showing only their tasks and their profile.

## Scope

In scope:
- Owner/admin can create employee auth users with role.
- A `clinic_tasks` table and CRUD flows.
- A "Tasks" tab in the owner/admin shell (global view, filter by employee + status).
- A separate two-tab home (My Tasks + Profile) for vet / receptionist / assistant roles.
- Status changes by either the assignee or owner/admin.

Out of scope (deliberately minimal):
- Due dates, priorities, attachments, comments on tasks.
- Multi-assignee tasks.
- Notifications / push.
- Linking tasks to appointments / pets / inventory.
- Self-signup for employees (the existing join-code flow is untouched).

## User stories

1. As an owner/admin, I open the Tasks tab, see all tasks in the clinic, and can filter by employee and status.
2. As an owner/admin, I tap "+", enter title + description, pick an assignee from a dropdown of clinic members, and save.
3. As an owner/admin, I open Members, tap "Add member," enter name + email + password + role, and submit. The new employee can immediately log in.
4. As an employee (vet/receptionist/assistant), I log in and land on a screen with two bottom-nav tabs: **My Tasks** and **Profile**. My Tasks lists only tasks where I am the assignee, grouped/filtered by status.
5. As either party, I can change a task's status (todo → in_progress → done) inline from the task row.

## Architecture

### Data model

New Postgres table `clinic_tasks`:

| Column        | Type        | Notes                                                   |
|---------------|-------------|---------------------------------------------------------|
| `id`          | uuid pk     | default `gen_random_uuid()`                             |
| `clinic_id`   | uuid        | fk → clinics, not null                                  |
| `title`       | text        | not null                                                |
| `description` | text        | nullable                                                |
| `assignee_id` | uuid        | fk → clinic_users.id, not null                          |
| `status`      | text        | check in ('todo','in_progress','done'), default 'todo'  |
| `created_by`  | uuid        | fk → clinic_users.id, not null                          |
| `created_at`  | timestamptz | default now()                                           |
| `updated_at`  | timestamptz | default now(), trigger to update on row change          |

Indexes: `(clinic_id, status)`, `(assignee_id, status)`.

### RLS policies

- **Select:** any `clinic_users` row in the same `clinic_id` can read all tasks of that clinic. (Owner/admin sees the global list; employees client-side filters by `assignee_id = me`. RLS-level employee-only restriction is rejected because the global list for admins requires the same read path — UI is the gate.)
- **Insert:** only roles `owner` or `admin` for that `clinic_id`.
- **Update:** owner/admin of that clinic, **or** the assignee of the row.
- **Delete:** owner/admin only.

Helper SQL function `current_clinic_user_role(clinic_id uuid) returns text` joins from `auth.uid()` → `clinic_users` to return the caller's role, used by the policies above.

### Employee creation — Edge Function

Client `signUp` cannot be used because it logs the new user in over the owner's session. Solution:

- New Supabase Edge Function `create-clinic-employee`.
- Auth: requires the caller's JWT. Function verifies the caller is an `owner` or `admin` in the target clinic (server-side check, not trusting client claims).
- Uses the service-role key (server-side only) to call `auth.admin.createUser({ email, password, email_confirm: true })`.
- Inserts a `clinic_users` row with `auth_user_id`, `clinic_id`, `full_name`, `role`, `account_status = 'active'`.
- Returns the new `clinic_users` row, or a structured error (email-in-use, forbidden, validation).
- Failure handling: if the auth user is created but the `clinic_users` insert fails, the function deletes the auth user to avoid orphans.

### Flutter layers

**Models**
- `lib/models/task.dart` — `ClinicTask` with `fromMap` / `toMap`, plus a `TaskStatus` enum.

**Service**
- `lib/services/task_service.dart`
  - `fetchTasks({String? assigneeId, TaskStatus? status})` — clinic-scoped list.
  - `fetchMyTasks()` — convenience wrapper using current clinic user id.
  - `createTask({title, description, assigneeId})`.
  - `updateStatus({taskId, status})`.
  - `deleteTask(taskId)`.
- `lib/services/clinic_member_service.dart` — add `createMember({fullName, email, password, role})` that invokes the `create-clinic-employee` Edge Function.

**Bloc / Cubits**
- `lib/bloc/tasks/tasks_cubit.dart` — list state for owner/admin (filters by employee + status) and for employee (filters by `me`).
- `lib/bloc/tasks/task_form_cubit.dart` — create-task form.
- `lib/bloc/clinic_member/member_form_cubit.dart` — create-employee form (new).

**Screens**
- `lib/screens/clinic/tasks/tasks_screen.dart` — owner/admin global task list with filter chips (employee dropdown, status segmented control), FAB to create.
- `lib/screens/clinic/tasks/task_form_dialog.dart` — title, description, assignee picker.
- `lib/screens/clinic/members/add_member_dialog.dart` — name, email, password, role (uses existing member-management screen as the entry point).
- `lib/screens/employee/employee_home.dart` — new bottom-nav shell for non-admin roles, two tabs:
  - `my_tasks_screen.dart` — list of assignee=me, grouped or filtered by status, with inline status change.
  - `profile_screen.dart` — name, email, role read-only + change password + log out.

**Routing**
- In `LoggedClinicCubit` (or a thin wrapper at app boot), after fetching the current `ClinicMember`, choose the home shell by role:
  - `owner` / `admin` → existing clinic shell + new Tasks tab in its bottom nav.
  - `vet` / `receptionist` / `assistant` → `EmployeeHome`.

### UI conventions

- Reuse existing `CustomTextField`, `CustomDropdownField`, `StatusChip`, `CustomAppbar` per the auto-memory guidance — no new one-off form primitives.
- Status displayed as a `StatusChip`. Tap chip → bottom-sheet to pick new status.

## Error handling

- Edge Function errors surfaced as user-facing strings (`Email already in use`, `Password too short`, `You don't have permission`).
- Task list: network failure shows a retry empty-state; no silent failure.
- Status update: optimistic UI; on failure revert and toast the error.

## Testing

- Unit: `TaskService` mocks Supabase client; verify queries built correctly.
- Unit: Edge Function — caller-role check (denied for non-owner/admin), orphan-rollback on `clinic_users` insert failure.
- Widget: `MyTasksScreen` renders only assignee=me, status change calls service.
- Manual: owner creates employee → employee logs in on a second device → sees two tabs → assigned task appears → status change reflects on owner's list.

## Open questions

None at design time. Edge Function URL/secret naming will be settled during implementation.
