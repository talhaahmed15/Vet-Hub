import 'package:flutter/material.dart';

class AppFonts {
  AppFonts._(); // prevents instantiation

  // ===== Font Family =====
  static const String inter = 'Inter';

  // ===== Base Style (internal) =====
  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = Colors.black,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: inter,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ===== Regular =====
  static TextStyle regular({
    double fontSize = 14,
    Color color = Colors.black,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return _base(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ===== Medium =====
  static TextStyle medium({
    double fontSize = 14,
    Color color = Colors.black,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return _base(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ===== SemiBold =====
  static TextStyle semiBold({
    double fontSize = 16,
    Color color = Colors.black,
    double height = 1.4,
    double letterSpacing = -0.2,
  }) {
    return _base(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ===== Bold =====
  static TextStyle bold({
    double fontSize = 16,
    Color color = Colors.black,
    double height = 1.4,
    double letterSpacing = -0.3,
  }) {
    return _base(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ===== Extra Bold (Optional but useful) =====
  static TextStyle extraBold({
    double fontSize = 18,
    Color color = Colors.black,
    double height = 1.3,
    double letterSpacing = -0.4,
  }) {
    return _base(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
