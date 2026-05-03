import 'package:clinic_management_app/models/enums/item_status_enum.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final InventoryStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.border),
      ),
      child: Text(
        status.label,
        style: AppFonts.semiBold(fontSize: 10, color: status.foreground),
      ),
    );
  }
}
