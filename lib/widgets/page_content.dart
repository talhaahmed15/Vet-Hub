import 'package:clinic_management_app/utils/responsive.dart';
import 'package:flutter/material.dart';

/// Constrains [child] to [maxWidth] and centers it horizontally on
/// tablet and desktop. On mobile it is a transparent pass-through.
///
/// Use [PageContent] as the top-level wrapper inside every screen's
/// Scaffold body so content never stretches uncomfortably wide.
///
/// Common widths:
///   • Auth / narrow forms    → maxWidth: 480
///   • Forms / detail screens → maxWidth: 600
///   • Settings screens       → maxWidth: 800
///   • Content / list screens → maxWidth: 960  (default)
///   • Wide dashboards        → maxWidth: 1200
///
/// Set [fillHeight] to true for screens whose body contains a [ListView],
/// [GridView], or a [Column] with [Expanded] children — these widgets
/// require a bounded height that the standard [Align] + [ConstrainedBox]
/// approach cannot provide.
class PageContent extends StatelessWidget {
  const PageContent({
    super.key,
    required this.child,
    this.maxWidth = 960,
    this.padding = EdgeInsets.zero,
    this.fillHeight = false,
  });

  final Widget child;

  /// Maximum content width on tablet/desktop.
  final double maxWidth;

  /// Optional padding applied inside the constrained container.
  final EdgeInsetsGeometry padding;

  /// When true, uses [LayoutBuilder] to provide both a bounded width and the
  /// full parent height to the child. Required for screens with [Expanded]
  /// children or viewports that need a bounded height (ListView, GridView).
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final content = padding == EdgeInsets.zero
        ? child
        : Padding(padding: padding, child: child);

    if (Responsive.isMobile(context)) return content;

    if (fillHeight) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, maxWidth);
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: content,
            ),
          );
        },
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }
}
