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
    final TextStyle baseStyle =
        itemTextStyle ??
        AppFonts.regular(
          color: isDark ? AppColors.white : AppColors.slate900,
          fontSize: 13,
        );

    final TextStyle selectedStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.primaryDeep,
    );

    return DropdownButtonFormField<T>(
      value: value,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      isDense: true,
      isExpanded: isExpanded,
      icon:
          icon ??
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.slate400,
          ),
      style: baseStyle,
      dropdownColor: isDark ? AppColors.darkGrey : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 6,
      menuMaxHeight: 320,
      decoration:
          decoration ??
          _inputDecoration(
            hint: hintText,
            isDark: isDark,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
      // Compact representation rendered inside the field (no check icon there).
      selectedItemBuilder: (context) => items
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                labelBuilder(item),
                style: baseStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: _DropdownItemRow<T>(
                label: labelBuilder(item),
                isSelected: value == item,
                isDark: isDark,
                baseStyle: baseStyle,
                selectedStyle: selectedStyle,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DropdownItemRow<T> extends StatelessWidget {
  const _DropdownItemRow({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.baseStyle,
    required this.selectedStyle,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final TextStyle baseStyle;
  final TextStyle selectedStyle;

  @override
  Widget build(BuildContext context) {
    final highlightBg = isDark
        ? AppColors.primaryDeep.withValues(alpha: 0.18)
        : AppColors.chipSelectedBg;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? highlightBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: isSelected ? selectedStyle : baseStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.primaryDeep,
            ),
          ],
        ],
      ),
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
    fillColor: isDark ? AppColors.darkGrey : AppColors.surface,
    hintStyle: AppFonts.regular(color: AppColors.slate400, fontSize: 12),
    errorStyle: AppFonts.regular(color: AppColors.error, fontSize: 10),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.disabled),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryDeep, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
  );
}
