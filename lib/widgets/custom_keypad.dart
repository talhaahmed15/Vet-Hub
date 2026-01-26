import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class CustomKeypad extends StatelessWidget {
  final Function(String) onKeyTap;
  final VoidCallback onBackspace;

  const CustomKeypad({
    super.key,
    required this.onKeyTap,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 260,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox();

                if (index == 11) {
                  return GestureDetector(
                    onTap: onBackspace,
                    child: Center(
                      child: Icon(
                        Icons.backspace_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  );
                }

                String keyVal = (index == 10) ? "0" : "${index + 1}";
                return _AnimatedKeypadButton(
                  label: keyVal,
                  onTap: () => onKeyTap(keyVal),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Home Indicator
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedKeypadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AnimatedKeypadButton({required this.label, required this.onTap});

  @override
  State<_AnimatedKeypadButton> createState() => _AnimatedKeypadButtonState();
}

class _AnimatedKeypadButtonState extends State<_AnimatedKeypadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: Matrix4.translationValues(0, _isPressed ? 3 : 0, 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Text(
          widget.label,
          style: AppFonts.bold(fontSize: 18).copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
