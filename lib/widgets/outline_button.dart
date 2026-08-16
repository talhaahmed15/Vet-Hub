import 'dart:developer';

import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class PrimaryOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;
  final bool fullWidth;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const PrimaryOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.borderColor = AppColors.primary,
    this.textColor = AppColors.primary,
    this.icon,
    this.fullWidth = true,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isEnabled ? textColor : AppColors.disabled;

    final button = OutlinedButton(
      onPressed: isLoading
          ? () => log("Button is loading...")
          : isEnabled
          ? onPressed
          : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isEnabled ? borderColor : AppColors.disabled,
          width: 1.5,
        ),
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 1.5,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: effectiveColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: AppFonts.medium(color: effectiveColor, fontSize: 14),
                ),
              ],
            ),
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height ?? 50,
      child: button,
    );
  }
}
