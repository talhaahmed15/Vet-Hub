import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDialog {
  /// Opens a time picker and returns the selected time as "HH:mm"
  static Future<String?> pickTime({
    required BuildContext context,
    String? initialTime, // optional initial time in "HH:mm"
  }) async {
    // Parse initialTime if provided
    TimeOfDay initial = TimeOfDay.now();
    if (initialTime != null) {
      final parts = initialTime.split(':');
      if (parts.length == 2) {
        initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? initial.hour,
          minute: int.tryParse(parts[1]) ?? initial.minute,
        );
      }
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary, // header background
              onPrimary: AppColors.white, // header text
              onSurface: AppColors.black, // body text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Format as "HH:mm"
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      return DateFormat('HH:mm').format(dt);
    }

    return null; // user canceled
  }

  static Future<bool?> confirmDelete({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: AppColors.darkGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                cancelText,
                style: const TextStyle(color: AppColors.darkGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}
