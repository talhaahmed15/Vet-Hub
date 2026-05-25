import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class AddMemberSheet extends StatefulWidget {
  static Future<bool> show(BuildContext context) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddMemberSheet._(),
    );
    return res == true;
  }

  const AddMemberSheet._();

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  String _role = ClinicRole.assistant.value;
  bool _submitting = false;

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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Member', style: AppFonts.semiBold(fontSize: 16)),
          12.height,
          Text('Full Name', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomTextField(controller: _name, hintText: 'Jane Doe'),
          12.height,
          Text('Username', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomTextField(controller: _username, hintText: 'jane'),
          12.height,
          Text('Password', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomTextField(
            controller: _password,
            hintText: 'Min 8 characters',
            obscureText: true,
          ),
          12.height,
          Text('Phone', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomTextField(
            controller: _phone,
            hintText: '+1 555 000 0000',
            keyboardType: TextInputType.phone,
          ),
          12.height,
          Text('Role', style: AppFonts.semiBold(fontSize: 12)),
          6.height,
          CustomDropdownField<String>(
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
          16.height,
          PrimaryButton(
            text: 'Create Member',
            isLoading: _submitting,
            isEnabled: !_submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
