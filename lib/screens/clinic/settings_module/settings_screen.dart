import 'package:clinic_management_app/models/clinic_member.dart';
import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/login_screen.dart';
import 'package:clinic_management_app/screens/clinic/settings_module/clinic_members_screen.dart';
import 'package:clinic_management_app/screens/clinic/settings_module/clinic_profile_screen.dart';
import 'package:clinic_management_app/services/auth_service.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ClinicMemberService _memberService = ClinicMemberService();
  late Future<_SettingsData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_SettingsData> _loadData() async {
    final clinicData = await Storage.getClinicData();
    final clinic = clinicData != null ? Clinic.fromMap(clinicData) : null;
    final member = await _memberService.fetchCurrentMember();
    return _SettingsData(clinic: clinic, member: member);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SettingsData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.white,
            body: PageContent(
              maxWidth: 800,
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final clinic = snapshot.data?.clinic;
        final member = snapshot.data?.member;
        final canManage = _canManage(member);

        return Scaffold(
          backgroundColor: AppColors.white,
          body: PageContent(
            maxWidth: 800,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ClinicHeader(clinic: clinic, member: member),
                  32.height,
                  _SectionTitle("CLINIC ADMINISTRATION"),
                  _SettingsTile(
                    icon: Icons.store_outlined,
                    title: "Clinic Profile",
                    subtitle: "Operating hours, address, and branding",
                    trailing: canManage
                        ? null
                        : const _Badge(label: "Admin Only"),
                    enabled: canManage,
                    onTap: () {
                      if (!canManage) {
                        AppToast.error(
                          context,
                          'Only admins can update the clinic profile.',
                        );
                        return;
                      }
                      NavigatorHelper.push(
                        context,
                        const ClinicProfileScreen(),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.group_outlined,
                    title: "User Management",
                    subtitle: "Manage staff roles and permissions",
                    trailing: canManage
                        ? null
                        : const _Badge(label: "Admin Only"),
                    enabled: canManage,
                    onTap: () {
                      if (!canManage) {
                        AppToast.error(
                          context,
                          'Only admins can manage users.',
                        );
                        return;
                      }
                      NavigatorHelper.push(
                        context,
                        ClinicMembersScreen(canManage: canManage),
                      );
                    },
                  ),
                  24.height,
                  _SectionTitle("APP PREFERENCES"),
                  const _SettingsTile(
                    icon: Icons.notifications_none,
                    title: "Notifications",
                    subtitle: "Patient alerts and clinic reminders",
                    trailing: _Badge(label: "Coming Soon"),
                    enabled: false,
                  ),
                  const _SettingsTile(
                    icon: Icons.hub_outlined,
                    title: "Integrations",
                    subtitle: "Connect IDEXX, Stripe, and Pharmacy",
                    trailing: _Badge(label: "Coming Soon"),
                    enabled: false,
                  ),
                  24.height,
                  _SectionTitle("SUPPORT"),
                  const _SettingsTile(
                    icon: Icons.help_outline,
                    title: "Help Center",
                    external: true,
                  ),
                  const _SettingsTile(
                    icon: Icons.info_outline,
                    title: "About VetFlow v2.4.1",
                  ),
                  32.height,
                  _SignOutButton(),
                  16.height,
                  if (member != null)
                    Center(
                      child: Text(
                        "Logged in as ${member.fullName}",
                        style: AppFonts.regular(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }
}

bool _canManage(ClinicMember? member) {
  final role = member?.role.toLowerCase();
  return role == 'owner' || role == 'admin';
}

class _SettingsData {
  final Clinic? clinic;
  final ClinicMember? member;

  const _SettingsData({required this.clinic, required this.member});
}

class _ClinicHeader extends StatelessWidget {
  final Clinic? clinic;
  final ClinicMember? member;

  const _ClinicHeader({this.clinic, this.member});

  @override
  Widget build(BuildContext context) {
    final clinicName = clinic?.clinicName?.trim().isNotEmpty == true
        ? clinic!.clinicName!.trim()
        : 'Vet Clinic';
    final clinicId = clinic?.clinicCode?.trim().isNotEmpty == true
        ? clinic!.clinicCode!.trim()
        : 'N/A';
    final roleLabel = member?.roleLabel ?? 'Staff';
    final statusLabel = member?.statusLabel ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(Icons.pets, size: 28, color: AppColors.primary),
          ),
          16.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(clinicName, style: AppFonts.semiBold(fontSize: 16)),
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
                    roleLabel,
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  8.width,
                  _Badge(label: statusLabel),
                ],
              ),
              6.height,
              Text(
                "Clinic Code: $clinicId",
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
  final VoidCallback? onTap;
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.external = false,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
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
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: enabled ? AppColors.primary : AppColors.grey,
            ),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.semiBold(
                    fontSize: 14,
                    color: enabled ? AppColors.black : AppColors.grey,
                  ),
                ),
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

    if (!enabled || onTap == null) {
      return Opacity(opacity: enabled ? 1 : 0.6, child: tile);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: tile,
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
  Future<void> _signOut(BuildContext context) async {
    try {
      final clinicData = await Storage.getClinicData();
      final clinic = clinicData != null ? Clinic.fromMap(clinicData) : null;

      await AuthService().signOutAndClear(clearClinic: false);
      if (!context.mounted) {
        return;
      }
      NavigatorHelper.replace(context, LoginScreen(clinic: clinic));
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _signOut(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
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
        ),
      ),
    );
  }
}
