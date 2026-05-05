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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.black;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.45) : AppColors.grey;
    final tileBg =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.transparent;
    final tileBorder =
        isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.divider;
    final securityBg = isDark
        ? AppColors.primary.withValues(alpha: 0.09)
        : AppColors.primary.withValues(alpha: 0.08);
    final securityBorder = isDark
        ? AppColors.primary.withValues(alpha: 0.22)
        : Colors.transparent;
    final securityTextColor =
        isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.black;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Review Details",
            style: AppFonts.bold(fontSize: 22, color: titleColor),
          ),
          4.height,
          Text(
            "Please review your information before submitting.",
            style: AppFonts.regular(color: subtitleColor, fontSize: 14),
          ),
          24.height,

          _ReviewTile(
            title: "Clinic Information",
            subtitle: formData.clinicName ?? "",
            icon: Icons.local_hospital_outlined,
            isDark: isDark,
            bg: tileBg,
            border: tileBorder,
          ),
          _ReviewTile(
            title: "Branding",
            subtitle: formData.tagLine ?? "",
            icon: Icons.palette_outlined,
            isDark: isDark,
            bg: tileBg,
            border: tileBorder,
          ),
          _ReviewTile(
            title: "Clinic Logo",
            subtitle: formData.logoUrl != null && formData.logoUrl!.isNotEmpty
                ? "Uploaded"
                : "Not uploaded",
            icon: Icons.photo_outlined,
            isDark: isDark,
            bg: tileBg,
            border: tileBorder,
          ),
          _ReviewTile(
            title: "Certificate",
            subtitle:
                formData.certificateUrl != null && formData.certificateUrl!.isNotEmpty
                    ? "Uploaded"
                    : "Not uploaded",
            icon: Icons.verified_outlined,
            isDark: isDark,
            bg: tileBg,
            border: tileBorder,
          ),
          _ReviewTile(
            title: "Services & Hours",
            subtitle: formData.workingDays
                    ?.join(', ') ??
                '',
            icon: Icons.schedule_outlined,
            isDark: isDark,
            bg: tileBg,
            border: tileBorder,
          ),
          _ReviewTile(
            title: "Package",
            subtitle: formData.packageName ?? formData.packageKey ?? "Not selected",
            icon: Icons.workspace_premium_outlined,
            isDark: isDark,
            bg: tileBg,
            border: tileBorder,
          ),

          8.height,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: securityBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: securityBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary),
                12.width,
                Expanded(
                  child: Text(
                    "Your information is secure and will only be used to set up your clinic.",
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: securityTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          32.height,
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final Color bg;
  final Color border;

  const _ReviewTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDark ? Colors.white.withValues(alpha: 0.82) : AppColors.black;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
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
                Text(title,
                    style: AppFonts.semiBold(fontSize: 14, color: titleColor)),
                4.height,
                Text(
                  subtitle,
                  style: AppFonts.regular(fontSize: 12, color: subtitleColor),
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
