import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

/// Material Design 3 adaptive breakpoints:
///   compact  → < 600px   (phone)
///   medium   → 600–1199px (tablet)
///   expanded → ≥ 1200px  (desktop / large web)
class Responsive {
  Responsive._();

  static const double _compactBreak = 600;
  static const double _mediumBreak = 1200;

  /// Fixed width of the desktop persistent sidebar.
  static const double sidebarWidth = 240;

  /// Fixed width of the tablet navigation rail.
  static const double railWidth = 72;

  /// Returns the [ScreenSize] for the current window width.
  /// Uses [MediaQuery.sizeOf] so it only rebuilds on size changes.
  static ScreenSize sizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < _compactBreak) return ScreenSize.compact;
    if (width < _mediumBreak) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static bool isMobile(BuildContext context) =>
      sizeOf(context) == ScreenSize.compact;

  static bool isTablet(BuildContext context) =>
      sizeOf(context) == ScreenSize.medium;

  static bool isDesktop(BuildContext context) =>
      sizeOf(context) == ScreenSize.expanded;

  /// Pick a value based on the current screen size.
  /// [tablet] falls back to [desktop] when omitted.
  ///
  /// Example:
  /// ```dart
  /// final cols = Responsive.value(context,
  ///   mobile: 1, tablet: 2, desktop: 3);
  /// ```
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    switch (sizeOf(context)) {
      case ScreenSize.compact:
        return mobile;
      case ScreenSize.medium:
        return tablet ?? desktop;
      case ScreenSize.expanded:
        return desktop;
    }
  }
}

/// Rebuilds [builder] whenever the [ScreenSize] bucket changes.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ScreenSize size) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.sizeOf(context));
  }
}
