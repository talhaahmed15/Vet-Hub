import 'package:clinic_management_app/models/task.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final ClinicTask task;
  final bool showAssignee;
  final ValueChanged<TaskStatus> onStatusChange;
  final VoidCallback? onDelete;

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
