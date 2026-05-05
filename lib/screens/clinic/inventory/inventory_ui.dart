import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

const Color _inventoryFieldBorder = AppColors.divider;
const Color _inventoryFieldFill = AppColors.white;
const Color _inventoryHintColor = AppColors.greyBlue;

InputDecoration inventoryInputDecoration({
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? suffixText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppFonts.regular(fontSize: 12, color: _inventoryHintColor),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    suffixText: suffixText,
    suffixStyle: AppFonts.semiBold(fontSize: 12, color: _inventoryHintColor),
    filled: true,
    fillColor: _inventoryFieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _inventoryFieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _inventoryFieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.error, width: 1.6),
    ),
  );
}

class InventorySectionHeader extends StatelessWidget {
  const InventorySectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            label.toUpperCase(),
            style: AppFonts.bold(
              fontSize: 12,
              color: AppColors.darkGrey.withValues(alpha: 0.8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
