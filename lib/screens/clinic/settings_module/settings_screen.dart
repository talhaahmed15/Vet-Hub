import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ClinicHeader(),
              32.height,
              _SectionTitle("CLINIC ADMINISTRATION"),
              _SettingsTile(
                icon: Icons.store_outlined,
                title: "Clinic Profile",
                subtitle: "Operating hours, address, and branding",
              ),
              _SettingsTile(
                icon: Icons.group_outlined,
                title: "User Management",
                subtitle: "Manage staff roles and permissions",
                trailing: _Badge(label: "3 Pending"),
              ),
              24.height,
              _SectionTitle("APP PREFERENCES"),
              _SettingsTile(
                icon: Icons.notifications_none,
                title: "Notifications",
                subtitle: "Patient alerts and clinic reminders",
              ),
              _SettingsTile(
                icon: Icons.hub_outlined,
                title: "Integrations",
                subtitle: "Connect IDEXX, Stripe, and Pharmacy",
              ),
              24.height,
              _SectionTitle("SUPPORT"),
              _SettingsTile(
                icon: Icons.help_outline,
                title: "Help Center",
                external: true,
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: "About VetFlow v2.4.1",
              ),
              32.height,
              _SignOutButton(),
              16.height,
              Center(
                child: Text(
                  "Logged in as admin@pawsandclaws.com",
                  style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: const Icon(Icons.pets, size: 28, color: AppColors.primary),
          ),
          16.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Paws & Claws Clinic",
                style: AppFonts.semiBold(fontSize: 16),
              ),
              6.height,
              Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  6.width,
                  Text(
                    "Administrator Access",
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              6.height,
              Text(
                "Clinic ID: VET-99283",
                style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppFonts.semiBold(
          fontSize: 12,
          letterSpacing: 1,
          color: AppColors.grey,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool external;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
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
                if (subtitle != null) ...[
                  4.height,
                  Text(
                    subtitle!,
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          Icon(
            external ? Icons.open_in_new : Icons.chevron_right,
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.semiBold(fontSize: 11, color: AppColors.white),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout, color: Colors.red),
          8.width,
          Text(
            "Sign Out",
            style: AppFonts.semiBold(fontSize: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
