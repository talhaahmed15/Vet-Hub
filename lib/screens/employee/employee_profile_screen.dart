import 'package:clinic_management_app/models/clinic_member.dart';
import 'package:clinic_management_app/screens/auth/app_start_screen.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  late Future<ClinicMember?> _me;

  @override
  void initState() {
    super.initState();
    _me = ClinicMemberService().fetchCurrentMember();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    await Storage.clearAllAuthAndClinic();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppStartScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Profile'),
      body: FutureBuilder<ClinicMember?>(
        future: _me,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final m = snap.data;
          if (m == null) {
            return Center(
              child: Text('Could not load profile.', style: AppFonts.regular()),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: 'Name', value: m.fullName),
                12.height,
                _Row(label: 'Role', value: m.roleLabel),
                12.height,
                _Row(label: 'Status', value: m.statusLabel),
                if (m.phone != null && m.phone!.trim().isNotEmpty) ...[
                  12.height,
                  _Row(label: 'Phone', value: m.phone!),
                ],
                const Spacer(),
                PrimaryButton(text: 'Log out', onPressed: _logout),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppFonts.semiBold(fontSize: 12)),
        ),
        Expanded(child: Text(value, style: AppFonts.regular(fontSize: 13))),
      ],
    );
  }
}
