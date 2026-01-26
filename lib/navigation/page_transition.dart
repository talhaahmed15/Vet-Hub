import 'package:flutter/material.dart';

enum PageTransitionType { slide, cupertino, fadeScale, sharedAxis }

class AppPageTransition {
  static PageRoute<T> build<T>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slide,
  }) {
    switch (type) {
      case PageTransitionType.cupertino:
        return _cupertino(page);
      case PageTransitionType.fadeScale:
        return _fadeScale(page);
      case PageTransitionType.sharedAxis:
        return _sharedAxis(page);
      case PageTransitionType.slide:
        return _slide(page);
    }
  }

  // ----------------- TRANSITIONS -----------------

  static PageRoute<T> _slide<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final offset =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final fade = Tween<double>(begin: 0, end: 1).animate(animation);

        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  static PageRoute<T> _cupertino<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final slide =
            Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
                reverseCurve: Curves.easeIn,
              ),
            );

        return SlideTransition(position: slide, child: child);
      },
    );
  }

  static PageRoute<T> _fadeScale<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

        final scale = Tween<double>(begin: 0.98, end: 1.0).animate(fade);

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  static PageRoute<T> _sharedAxis<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final slide =
            Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final fade = Tween<double>(begin: 0, end: 1).animate(animation);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
