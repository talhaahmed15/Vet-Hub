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
                text: 'Create Task',
                isLoading: submitting,
                isEnabled: !submitting,
                onPressed: () => context.read<TaskFormCubit>().submit(
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
