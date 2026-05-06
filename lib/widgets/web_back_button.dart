import 'package:flutter/material.dart';

class WebBackButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const WebBackButton({super.key, this.onPressed});

  @override
  State<WebBackButton> createState() => _WebBackButtonState();
}

class _WebBackButtonState extends State<WebBackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _bgOpacity;
  late final Animation<double> _borderOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _bgOpacity = Tween<double>(begin: 0.08, end: 0.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _borderOpacity = Tween<double>(begin: 0.14, end: 0.38).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onEnter(_) => _ctrl.forward();
  void _onExit(_) => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed ?? () => Navigator.of(context).pop(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _bgOpacity.value),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: _borderOpacity.value),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white.withValues(alpha: 0.75),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
