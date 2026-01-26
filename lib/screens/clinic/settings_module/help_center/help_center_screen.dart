import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        leading: const BackButton(color: AppColors.primary),
        title: Text("Help Center", style: AppFonts.semiBold(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpHeader(),
            24.height,
            _HelpTile(
              icon: Icons.book_outlined,
              title: "Getting Started",
              subtitle: "Learn how to set up your clinic and staff",
            ),
            _HelpTile(
              icon: Icons.calendar_today_outlined,
              title: "Appointments & Scheduling",
              subtitle: "Manage bookings and reminders",
            ),
            _HelpTile(
              icon: Icons.receipt_long_outlined,
              title: "Billing & Payments",
              subtitle: "Invoices, payments, and refunds",
            ),
            _HelpTile(
              icon: Icons.people_outline,
              title: "Staff & Permissions",
              subtitle: "Roles, access levels, and invites",
            ),
            _HelpTile(
              icon: Icons.support_agent,
              title: "Contact Support",
              subtitle: "Reach out to our support team",
              external: true,
            ),
            32.height,
            _SupportFooter(),
          ],
        ),
      ),
    );
  }
}

class _HelpHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.help_outline, size: 36, color: AppColors.primary),
          12.width,
          Expanded(
            child: Text(
              "Need help? Find quick answers or contact our support team.",
              style: AppFonts.regular(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool external;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.external = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
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
            external ? Icons.open_in_new : Icons.chevron_right,
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }
}

class _SupportFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Support Hours: Mon–Fri, 9:00 AM – 6:00 PM\nsupport@vetflow.app",
        textAlign: TextAlign.center,
        style: AppFonts.regular(
          fontSize: 12,
          color: AppColors.grey,
          height: 1.5,
        ),
      ),
    );
  }
}
