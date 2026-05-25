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
                  final state = context.watch<TasksCubit>().state;
                  final loaded = state is TasksLoaded ? state : null;
                  return Row(
                    children: [
                      Expanded(
                        child: CustomDropdownField<String?>(
                          items: <String?>[null, ...members.map((m) => m.id)],
                          value: loaded?.assigneeFilter,
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
                          value: loaded?.statusFilter,
                          labelBuilder: (s) =>
                              s == null ? 'All statuses' : s.label,
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
                    separatorBuilder: (_, _) => 12.height,
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
