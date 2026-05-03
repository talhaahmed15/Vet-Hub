import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String hintText;
  final String Function(T) labelBuilder;
  final bool isExpanded;
  final bool isDark;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? icon;
  final TextStyle? itemTextStyle;
  final FormFieldValidator<T>? validator;
  final InputDecoration? decoration;

  const CustomDropdownField({
    super.key,
    required this.items,
    required this.hintText,
    required this.labelBuilder,
    this.value,
    this.onChanged,
    this.isExpanded = true,
    this.isDark = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.icon,
    this.itemTextStyle,
    this.validator,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      isDense: true,
      isExpanded: isExpanded,
      icon:
          icon ??
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey),
      style:
          itemTextStyle ??
          AppFonts.regular(
            color: isDark ? AppColors.white : AppColors.black,
            fontSize: 12,
          ),
      dropdownColor: isDark ? AppColors.darkGrey : AppColors.white,
      decoration:
          decoration ??
          _inputDecoration(
            hint: hintText,
            isDark: isDark,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style:
                    itemTextStyle ??
                    AppFonts.regular(
                      color: isDark ? AppColors.white : AppColors.black,
                      fontSize: 12,
                    ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required bool isDark,
  Widget? suffixIcon,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffixIcon,
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: isDark ? AppColors.darkGrey : AppColors.white,
    hintStyle: AppFonts.regular(color: AppColors.grey, fontSize: 12),
    errorStyle: AppFonts.regular(color: AppColors.error, fontSize: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.disabled),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
  );
}
