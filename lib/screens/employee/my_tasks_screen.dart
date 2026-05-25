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
              separatorBuilder: (_, _) => 12.height,
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
