import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const TermsConditionsScreen({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Last updated: October 2023',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _Section(
                    title: '1. Introduction',
                    text:
                        'Welcome to VetConnect. By using our platform, you agree to these terms.',
                  ),
                  _Section(
                    title: '2. Data Privacy',
                    text:
                        'Your clinic data is encrypted and never sold to third parties.',
                  ),
                  _Section(
                    title: '3. User Responsibilities',
                    text:
                        'You are responsible for maintaining account confidentiality.',
                  ),
                  _Section(
                    title: '4. Service Limitations',
                    text: 'VetConnect does not provide medical advice.',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                PrimaryButton(text: 'Accept & Continue', onPressed: onAccept),
                TextButton(
                  onPressed: onDecline,
                  child: const Text(
                    'Decline',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String text;

  const _Section({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
