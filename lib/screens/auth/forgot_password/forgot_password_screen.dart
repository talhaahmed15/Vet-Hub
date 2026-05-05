import 'package:clinic_management_app/widgets/app_input.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

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
                onPressed: onBack,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter your email to receive reset instructions',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            AppInput(label: 'Email Address', hint: 'name@clinic.com'),
            PrimaryButton(text: 'Send Reset Link', onPressed: () {}),
            const Spacer(),
            TextButton(
              onPressed: onBack,
              child: const Text('Remember password? Log In'),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
