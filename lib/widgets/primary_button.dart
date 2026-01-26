import 'dart:developer';

import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = isEnabled ? AppColors.primary : AppColors.disabled;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading
            ? () => log("Button is loading...")
            : isEnabled
            ? onPressed
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: AppColors.disabled,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 2,
          shadowColor: isEnabled
              ? AppColors.primary.withOpacity(0.6)
              : Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 1.5,
                ),
              )
            : Text(
                text,
                style: AppFonts.medium(color: AppColors.white, fontSize: 14),
              ),
      ),
    );
  }
}
