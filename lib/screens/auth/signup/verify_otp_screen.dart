import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class VerifyOTPScreen extends StatefulWidget {
  final VoidCallback onVerify;
  final VoidCallback onBack;

  const VerifyOTPScreen({
    super.key,
    required this.onVerify,
    required this.onBack,
  });

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> {
  final List<TextEditingController> controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageContent(
        maxWidth: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Email',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter the 4-digit code sent to your email',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 60,
                  child: TextField(
                    controller: controllers[i],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(text: 'Verify Account', onPressed: widget.onVerify),
            TextButton(onPressed: () {}, child: const Text('Resend OTP')),
          ],
        ),
        ),
      ),
    );
  }
}
