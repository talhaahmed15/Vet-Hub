import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({required this.formData, super.key});

  final Clinic formData;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Review Details", style: AppFonts.bold(fontSize: 22)),
          4.height,
          Text(
            "Please review your information before submitting.",
            style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
          ),
          24.height,

          _ReviewTile(
            title: "Clinic Information",
            subtitle: formData.clinicName ?? "",
            icon: Icons.local_hospital_outlined,
          ),
          _ReviewTile(
            title: "Branding",
            subtitle: formData.tagLine ?? "",
            icon: Icons.palette_outlined,
          ),
          _ReviewTile(
            title: "Clinic Logo",
            subtitle: formData.logoUrl ?? "",
            icon: Icons.photo_outlined,
          ),
          _ReviewTile(
            title: "Certificate",
            subtitle: formData.certificateUrl ?? "",
            icon: Icons.verified_outlined,
          ),
          _ReviewTile(
            title: "Services & Hours",
            subtitle: formData.workingDays
                .toString()
                .replaceAll('[', "")
                .replaceAll(']', ""),
            icon: Icons.schedule_outlined,
          ),
          _ReviewTile(
            title: "Package",
            subtitle: formData.packageName ??
                formData.packageKey ??
                "Not selected",
            icon: Icons.workspace_premium_outlined,
          ),

          8.height,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary),
                12.width,
                Expanded(
                  child: Text(
                    "Your information is secure and will only be used to set up your clinic.",
                    style: AppFonts.regular(fontSize: 12),
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

class _ReviewTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ReviewTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.semiBold(fontSize: 14)),
                4.height,
                Text(
                  subtitle,
                  style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }
}
