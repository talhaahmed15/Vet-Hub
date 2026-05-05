import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool isDark;
  final bool obscureText;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final int? maxLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final Function()? onTap;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const CustomTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.keyboardType,
    this.isDark = false,
    this.obscureText = false,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.onTap,
    this.validator,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDark =
        widget.isDark || Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText ? _obscure : false,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      validator: widget.validator,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      style: AppFonts.regular(
        color: effectiveDark
            ? Colors.white.withValues(alpha: 0.88)
            : AppColors.black,
        fontSize: 14,
      ),
      cursorColor: effectiveDark ? AppColors.primary : AppColors.black,
      cursorErrorColor: AppColors.error,
      decoration: _inputDecoration(
        hint: widget.hintText,
        isDark: effectiveDark,
        suffix: _buildSuffixIcon(effectiveDark),
        prefixIcon: widget.prefixIcon,
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isDark) {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscure ? Icons.visibility : Icons.visibility_off,
          color: isDark ? Colors.white.withValues(alpha: 0.45) : AppColors.grey,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    }
    return widget.suffixIcon;
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required bool isDark,
  Widget? suffix,
  Widget? prefixIcon,
}) {
  final borderColor = isDark
      ? Colors.white.withValues(alpha: 0.16)
      : AppColors.divider;

  return InputDecoration(
    hintText: hint,
    suffixIcon: suffix,
    prefixIcon: prefixIcon,
    prefixIconColor: isDark ? Colors.white.withValues(alpha: 0.4) : null,
    filled: true,
    fillColor: isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.white,
    hintStyle: AppFonts.regular(
      color: isDark
          ? Colors.white.withValues(alpha: 0.3)
          : AppColors.grey,
      fontSize: 14,
    ),
    errorStyle: AppFonts.regular(
      color: isDark ? const Color(0xFFFF5252) : AppColors.error,
      fontSize: 12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: borderColor),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.disabled,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
