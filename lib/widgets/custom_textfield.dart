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
        color: widget.isDark ? AppColors.white : AppColors.black,
        fontSize: 12,
      ),
      cursorColor: AppColors.black,
      cursorErrorColor: AppColors.error,
      decoration: _inputDecoration(
        hint: widget.hintText,
        isDark: widget.isDark,
        suffix: _buildSuffixIcon(),
        prefixIcon: widget.prefixIcon,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscure ? Icons.visibility : Icons.visibility_off,
          color: AppColors.grey,
        ),
        onPressed: () {
          setState(() {
            _obscure = !_obscure;
          });
        },
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
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffix,
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
