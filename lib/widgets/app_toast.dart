import 'dart:async';

import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color color = AppColors.primary,
    Duration duration = const Duration(seconds: 2),
  }) {
    _remove();

    final overlay = Overlay.of(context);
    late AnimationController controller;

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: _ToastAnimation(
            color: color,
            icon: icon,
            message: message,
            onInit: (c) => controller = c,
          ),
        );
      },
    );

    overlay.insert(entry);
    _entry = entry;

    _timer = Timer(duration, () async {
      await controller.reverse();
      _remove();
    });
  }

  static void _remove() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      color: AppColors.primary,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.info_outline,
      color: AppColors.error,
    );
  }
}

class _ToastAnimation extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color color;
  final Function(AnimationController) onInit;

  const _ToastAnimation({
    required this.message,
    required this.color,
    required this.onInit,
    this.icon,
  });

  @override
  State<_ToastAnimation> createState() => _ToastAnimationState();
}

class _ToastAnimationState extends State<_ToastAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    widget.onInit(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: AppColors.white, size: 20),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    widget.message,
                    style: AppFonts.medium(
                      fontSize: 12,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
