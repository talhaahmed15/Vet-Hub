import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final Function()? onTap;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final bool enabled;
  final bool readOnly;
  final int? maxLines;

  const SearchTextField({
    super.key,
    this.controller,
    required this.hint,
    this.onChanged,
    this.onTap,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.search,
    this.keyboardType,
    this.onSubmitted,
    this.prefixIcon = const Icon(
      Icons.search_rounded,
      color: AppColors.greyBlue,
    ),
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      validator: validator,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: AppFonts.regular(fontSize: 12, color: AppColors.black),
      cursorColor: AppColors.black,
      cursorErrorColor: AppColors.error,
      decoration: _searchInputDecoration(
        hint: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

InputDecoration _searchInputDecoration({
  required String hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  // Keep SAME styling you requested: bg color, font colors, and roundness.
  const fill = Color(0xFFF1F6FB);
  const borderColor = Color(0xFFE1ECFA);
  const hintColor = Color(0xFF4E739D);
  const radius = 6.0;

  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: AppFonts.medium(fontSize: 12, color: hintColor),

    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,

    filled: true,
    fillColor: fill,

    // Similar behavior to CustomTextField (borders for states)
    border: border(borderColor),
    enabledBorder: border(borderColor),
    disabledBorder: border(AppColors.disabled),
    focusedBorder: border(AppColors.primary, width: 2),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error, width: 2),

    // Similar “feel” to your SearchTextField padding
    contentPadding: const EdgeInsets.symmetric(vertical: 8),

    // Same error typography approach as CustomTextField
    errorStyle: AppFonts.regular(color: AppColors.error, fontSize: 10),
  );
}
