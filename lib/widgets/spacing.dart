import 'package:flutter/widgets.dart';

extension SpacingExtension on num {
  /// Vertical space
  SizedBox get height => SizedBox(height: toDouble());

  /// Horizontal space
  SizedBox get width => SizedBox(width: toDouble());
}
