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

  const PrimaryOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.borderColor = AppColors.primary,
    this.textColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
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
            : Text(
                text,
                style: AppFonts.medium(
                  color: isEnabled ? textColor : AppColors.disabled,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}
