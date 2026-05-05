import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class PrimaryIconButton extends StatelessWidget {
  const PrimaryIconButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.foregroundColor,
    this.shadowColor,
    this.loadingIndicatorColor,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final Color? foregroundColor;
  final Color? shadowColor;
  final Color? loadingIndicatorColor;

  @override
  Widget build(BuildContext context) {
    final resolvedBackgroundColor =
        backgroundColor ?? AppColors.primary;
    final resolvedDisabledColor =
        disabledBackgroundColor ?? AppColors.disabled;
    final resolvedForegroundColor =
        foregroundColor ?? AppColors.white;
    final resolvedShadowColor = shadowColor ??
        (isEnabled
            ? resolvedBackgroundColor.withValues(alpha: 0.6)
            : Colors.transparent);
    final buttonColor =
        isEnabled ? resolvedBackgroundColor : resolvedDisabledColor;

    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isLoading
              ? () {}
              : isEnabled
              ? onPressed
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            disabledBackgroundColor: resolvedDisabledColor,
            elevation: 2,
            shadowColor: resolvedShadowColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: loadingIndicatorColor ?? resolvedForegroundColor,
                    strokeWidth: 1.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: resolvedForegroundColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: AppFonts.medium(
                        color: resolvedForegroundColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
