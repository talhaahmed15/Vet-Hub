import 'dart:developer';

import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;

  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = isEnabled
        ? backgroundColor
        : AppColors.disabled.withValues(alpha: 0.5);
    final effectiveTextColor = isEnabled
        ? textColor
        : AppColors.white.withValues(alpha: 0.7);
    final effectiveBorder = borderColor != null
        ? (isEnabled ? BorderSide(color: borderColor!) : BorderSide.none)
        : BorderSide.none;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isLoading
            ? () => log("Button is loading...")
            : isEnabled
            ? onPressed
            : null,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 1.5,
                ),
              )
            : Icon(icon, color: effectiveTextColor),
        label: isLoading
            ? const SizedBox.shrink()
            : Text(
                label,
                style: AppFonts.medium(color: effectiveTextColor, fontSize: 12),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: effectiveBorder,
          ),
        ),
      ),
    );
  }
}
