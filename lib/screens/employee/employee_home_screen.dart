import 'package:clinic_management_app/bloc/tasks/tasks_cubit.dart';
import 'package:clinic_management_app/screens/employee/employee_profile_screen.dart';
import 'package:clinic_management_app/screens/employee/my_tasks_screen.dart';
import 'package:clinic_management_app/services/task_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _index = 0;

  final List<Widget> _pages = [
    BlocProvider(
      create: (ctx) => TasksCubit(service: ctx.read<TaskService>()),
      child: const MyTasksScreen(),
    ),
    const EmployeeProfileScreen(),
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
