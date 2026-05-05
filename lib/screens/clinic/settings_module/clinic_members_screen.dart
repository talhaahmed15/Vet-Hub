import 'package:clinic_management_app/models/clinic_member.dart';
import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class ClinicMembersScreen extends StatefulWidget {
  const ClinicMembersScreen({super.key, required this.canManage});

  final bool canManage;

  @override
  State<ClinicMembersScreen> createState() => _ClinicMembersScreenState();
}

class _ClinicMembersScreenState extends State<ClinicMembersScreen> {
  final ClinicMemberService _service = ClinicMemberService();
  late Future<List<ClinicMember>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _service.fetchMembers();
  }

  void _reload() {
    setState(() {
      _membersFuture = _service.fetchMembers();
    });
  }

  Future<void> _editMember(ClinicMember member) async {
    if (!widget.canManage) return;
    final fullNameController = TextEditingController(text: member.fullName);
    final phoneController = TextEditingController(text: member.phone ?? '');
    var selectedRole = member.role.isNotEmpty ? member.role : ClinicRole.vet.value;
    var selectedStatus =
        member.accountStatus.isNotEmpty ? member.accountStatus : 'active';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
              Text('Edit Member', style: AppFonts.semiBold(fontSize: 16)),
              12.height,
              Text('Full Name', style: AppFonts.semiBold(fontSize: 12)),
              6.height,
              CustomTextField(
                controller: fullNameController,
                hintText: 'Full name',
              ),
              12.height,
              Text('Phone', style: AppFonts.semiBold(fontSize: 12)),
              6.height,
              CustomTextField(
                controller: phoneController,
                hintText: '+1 555 000 0000',
                keyboardType: TextInputType.phone,
              ),
              12.height,
              Text('Role', style: AppFonts.semiBold(fontSize: 12)),
              6.height,
              CustomDropdownField<String>(
                items: ClinicRole.values.map((role) => role.value).toList(),
                value: selectedRole,
                labelBuilder: (value) {
                  final role = ClinicRole.values.firstWhere(
                    (entry) => entry.value == value,
                    orElse: () => ClinicRole.vet,
                  );
                  return role.label;
                },
                hintText: 'Select role',
                onChanged: (value) {
                  if (value != null) selectedRole = value;
                },
              ),
              12.height,
              Text('Account Status', style: AppFonts.semiBold(fontSize: 12)),
              6.height,
              CustomDropdownField<String>(
                items: const ['active', 'under_review', 'blocked'],
                value: selectedStatus,
                labelBuilder: (value) {
                  switch (value) {
                    case 'active':
                      return 'Active';
                    case 'under_review':
                      return 'Under Review';
                    case 'blocked':
                      return 'Blocked';
                    default:
                      return value;
                  }
                },
                hintText: 'Select status',
                onChanged: (value) {
                  if (value != null) selectedStatus = value;
                },
              ),
              16.height,
              PrimaryButton(
                text: 'Save Changes',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      try {
        await _service.updateMember(
          memberId: member.id,
          fullName: fullNameController.text,
          phone: phoneController.text,
          role: selectedRole,
          accountStatus: selectedStatus,
        );
        AppToast.success(context, 'Member updated.');
        _reload();
      } catch (e) {
        AppToast.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'User Management',
        trailing: IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ),
      body: PageContent(
        maxWidth: 800,
        fillHeight: true,
        child: FutureBuilder<List<ClinicMember>>(
          future: _membersFuture,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load members.',
                style: AppFonts.regular(),
              ),
            );
          }

          final members = snapshot.data ?? const [];
          if (members.isEmpty) {
            return Center(
              child: Text('No members found.', style: AppFonts.regular()),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => 12.height,
            itemBuilder: (context, index) {
              final member = members[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        member.fullName.isNotEmpty
                            ? member.fullName.substring(0, 1).toUpperCase()
                            : 'U',
                        style: AppFonts.semiBold(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    12.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName.isNotEmpty
                                ? member.fullName
                                : 'Unnamed user',
                            style: AppFonts.semiBold(fontSize: 14),
                          ),
                          4.height,
                          Text(
                            member.roleLabel,
                            style: AppFonts.regular(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                          if (member.phone != null &&
                              member.phone!.trim().isNotEmpty) ...[
                            4.height,
                            Text(
                              member.phone!,
                              style: AppFonts.regular(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StatusPill(label: member.statusLabel),
                    if (widget.canManage) ...[
                      8.width,
                      IconButton(
                        onPressed: () => _editMember(member),
                        icon: const Icon(Icons.edit, size: 20),
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final color = normalized.contains('active')
        ? Colors.green
        : normalized.contains('blocked')
        ? Colors.red
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppFonts.semiBold(fontSize: 11, color: color),
      ),
    );
  }
}
