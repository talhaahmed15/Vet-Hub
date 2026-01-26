import 'package:flutter/material.dart';

class AppInput extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType type;

  const AppInput({
    super.key,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          obscureText: obscure,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
