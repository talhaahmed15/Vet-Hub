import 'dart:async';

import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:flutter/material.dart';

class _ToastData {
  final Object id;
  final String message;
  final String? title;
  final IconData? icon;
  final Color color;

  const _ToastData({
    required this.id,
    required this.message,
    this.title,
    this.icon,
    required this.color,
  });
}

class AppToast {
  static OverlayEntry? _overlayEntry;
  static final _items = ValueNotifier<List<_ToastData>>([]);
  static final _timers = <Object, Timer>{};
  static final _cards = <Object, _ToastCardState>{};
  static const _max = 5;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    IconData? icon,
    Color color = AppColors.primary,
    Duration duration = const Duration(seconds: 3),
  }) {
    while (_items.value.length >= _max) {
      _dismissNow(_items.value.first.id);
    }

    _ensureOverlay(context);

    final id = Object();
    _items.value = [
      ..._items.value,
      _ToastData(id: id, message: message, title: title, icon: icon, color: color),
    ];
    _timers[id] = Timer(duration, () => _dismiss(id));
  }

  static void _ensureOverlay(BuildContext context) {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (_) => _ToastOverlay(items: _items, onDismiss: _dismiss),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  static Future<void> _dismiss(Object id) async {
    if (!_items.value.any((t) => t.id == id)) return;
    _timers[id]?.cancel();
    _timers.remove(id);
    final card = _cards[id];
    if (card != null && card.mounted) {
      await card.animateOut();
    }
    _dismissNow(id);
  }

  static void _dismissNow(Object id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    _cards.remove(id);
    final updated = _items.value.where((t) => t.id != id).toList();
    _items.value = updated;
    if (updated.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  static void success(BuildContext context, String message, {String? title}) =>
      show(
        context,
        message: message,
        title: title,
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );

  static void error(BuildContext context, String message, {String? title}) =>
      show(
        context,
        message: message,
        title: title,
        icon: Icons.cancel_rounded,
        color: AppColors.error,
      );

  static void warning(BuildContext context, String message, {String? title}) =>
      show(
        context,
        message: message,
        title: title,
        icon: Icons.warning_rounded,
        color: AppColors.warning,
      );

  static void info(BuildContext context, String message, {String? title}) =>
      show(
        context,
        message: message,
        title: title,
        icon: Icons.info_rounded,
        color: AppColors.info,
      );
}

class _ToastOverlay extends StatelessWidget {
  final ValueNotifier<List<_ToastData>> items;
  final Future<void> Function(Object) onDismiss;

  const _ToastOverlay({required this.items, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final content = ValueListenableBuilder<List<_ToastData>>(
      valueListenable: items,
      builder: (_, list, _) {
        final ordered = isMobile ? list : list.reversed.toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
          children: ordered
              .map(
                (data) => Padding(
                  padding: EdgeInsets.only(
                    top: isMobile ? 0 : 8,
                    bottom: isMobile ? 8 : 0,
                  ),
                  child: _ToastCard(
                    key: ValueKey(data.id),
                    data: data,
                    isMobile: isMobile,
                    onDismiss: () => onDismiss(data.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    );

    if (isMobile) {
      return Positioned(bottom: 24, left: 16, right: 16, child: content);
    }

    return Positioned(top: 24, right: 24, child: content);
  }
}

class _ToastCard extends StatefulWidget {
  final _ToastData data;
  final bool isMobile;
  final VoidCallback onDismiss;

  const _ToastCard({
    super.key,
    required this.data,
    required this.isMobile,
    required this.onDismiss,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    AppToast._cards[widget.data.id] = this;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.isMobile ? const Offset(0, 0.4) : const Offset(0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  Future<void> animateOut() async {
    if (mounted) await _ctrl.reverse();
  }

  @override
  void dispose() {
    AppToast._cards.remove(widget.data.id);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.isMobile ? _mobileCard() : _desktopCard(),
      ),
    );
  }

  Widget _desktopCard() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: widget.data.color, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.data.icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  widget.data.icon,
                  color: widget.data.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.data.title != null) ...[
                    Text(
                      widget.data.title!,
                      style: AppFonts.semiBold(
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    widget.data.message,
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close, size: 15, color: AppColors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileCard() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: widget.data.color.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (widget.data.icon != null) ...[
              Icon(widget.data.icon, color: AppColors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.data.title != null) ...[
                    Text(
                      widget.data.title!,
                      style: AppFonts.semiBold(
                        fontSize: 13,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    widget.data.message,
                    style: AppFonts.medium(
                      fontSize: 12,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
