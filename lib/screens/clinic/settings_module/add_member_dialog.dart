import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/modern_dialog.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddMemberDialog extends StatefulWidget {
  static Future<bool> show(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddMemberDialog._(),
    );
    return res == true;
  }

  const AddMemberDialog._();

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  String _role = ClinicRole.assistant.value;
  bool _submitting = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 3) {
      AppToast.error(context, 'Full name must be at least 3 characters.');
      return;
    }
    if (_username.text.trim().length < 3) {
      AppToast.error(context, 'Username must be at least 3 characters.');
      return;
    }
    if (_password.text.length < 8) {
      AppToast.error(context, 'Password must be at least 8 characters.');
      return;
    }
    if (_phone.text.trim().length < 5) {
      AppToast.error(context, 'Phone is required.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ClinicMemberService().createMember(
        fullName: _name.text,
        username: _username.text,
        password: _password.text,
        phone: _phone.text,
        role: _role,
      );
      if (!mounted) return;
      AppToast.success(context, 'Member created.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernDialog(
      icon: LucideIcons.userPlus,
      accent: AppColors.primary,
      title: 'Invite Team Member',
      subtitle: 'Create credentials and assign a clinic role.',
      width: 460,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernField(
            label: 'FULL NAME',
            icon: LucideIcons.user,
            child: CustomTextField(controller: _name, hintText: 'Jane Doe'),
          ),
          ModernField(
            label: 'USERNAME',
            icon: LucideIcons.atSign,
            child: CustomTextField(controller: _username, hintText: 'jane'),
          ),
          ModernField(
            label: 'PASSWORD',
            icon: LucideIcons.lock,
            helper: 'Minimum 8 characters.',
            child: CustomTextField(
              controller: _password,
              hintText: 'Set a strong password',
              obscureText: !_passwordVisible,
              suffixIcon: IconButton(
                splashRadius: 18,
                icon: Icon(
                  _passwordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 16,
                  color: AppColors.slate400,
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
            ),
          ),
          ModernField(
            label: 'PHONE',
            icon: LucideIcons.phone,
            child: CustomTextField(
              controller: _phone,
              hintText: '+1 555 000 0000',
              keyboardType: TextInputType.phone,
            ),
          ),
          ModernField(
            label: 'ROLE',
            icon: LucideIcons.shieldUser,
            child: CustomDropdownField<String>(
              items: ClinicRole.values
                  .where((r) => r != ClinicRole.owner)
                  .map((r) => r.value)
                  .toList(),
              value: _role,
              labelBuilder: (v) {
                final r = ClinicRole.values.firstWhere(
                  (e) => e.value == v,
                  orElse: () => ClinicRole.assistant,
                );
                return r.label;
              },
              hintText: 'Select role',
              onChanged: (v) {
                if (v != null) setState(() => _role = v);
              },
            ),
          ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: PrimaryOutlinedButton(
              text: 'Cancel',
              onPressed: _submitting
                  ? () {}
                  : () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              text: 'Create Member',
              isLoading: _submitting,
              isEnabled: !_submitting,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
