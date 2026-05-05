import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class AboutVetFlowScreen extends StatelessWidget {
  const AboutVetFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: "About Us"),
      body: PageContent(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _AppHeader(),
              24.height,
              _InfoCard(
                title: "What is VetFlow?",
                description:
                    "VetFlow is an all-in-one clinic management platform designed "
                    "to simplify veterinary operations. From appointments and "
                    "patient records to billing and staff management — VetFlow "
                    "helps clinics operate efficiently and focus on animal care.",
              ),
              _InfoCard(
                title: "Version",
                description: "VetFlow v2.4.1\nRelease Date: January 2026",
              ),
              _InfoCard(
                title: "Developed By",
                description:
                    "VetFlow Technologies\nCrafted with ❤️ for modern veterinary clinics.",
              ),
              _InfoCard(
                title: "Legal",
                description: "© 2026 VetFlow Technologies\nAll rights reserved.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 84,
          width: 84,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets, size: 40, color: AppColors.primary),
        ),
        16.height,
        Text("VetFlow", style: AppFonts.semiBold(fontSize: 20)),
        6.height,
        Text(
          "Smart Clinic. Better Care.",
          style: AppFonts.regular(fontSize: 13, color: AppColors.grey),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String description;

  const _InfoCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppFonts.semiBold(fontSize: 14)),
          8.height,
          Text(
            description,
            style: AppFonts.regular(
              fontSize: 13,
              color: AppColors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
