import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:flutter/material.dart';

class LightTheme {
  static ThemeData theme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.white,
    primaryColor: AppColors.secondary,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 14),
    ),

    // inputDecorationTheme: InputDecorationTheme(
    //   filled: true,
    //   fillColor: const Color(0xFFF6F6F6),
    //   border: OutlineInputBorder(
    //     borderRadius: BorderRadius.circular(12),
    //     borderSide: BorderSide.none,
    //   ),
    // ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F378A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
