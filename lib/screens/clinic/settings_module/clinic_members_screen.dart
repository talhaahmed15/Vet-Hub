import 'package:clinic_management_app/models/clinic_member.dart';
import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:clinic_management_app/screens/clinic/settings_module/add_member_dialog.dart';
import 'package:clinic_management_app/services/clinic_member_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/modern_dialog.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ClinicMembersScreen extends StatefulWidget {
  const ClinicMembersScreen({
    super.key,
    this.canManage,
    this.showAppBar = true,
  });

  /// When null the screen resolves the current member's role to decide.
  final bool? canManage;
  final bool showAppBar;

  @override
  State<ClinicMembersScreen> createState() => _ClinicMembersScreenState();
}

class _ClinicMembersScreenState extends State<ClinicMembersScreen> {
  final ClinicMemberService _service = ClinicMemberService();
  final TextEditingController _searchController = TextEditingController();
  late Future<_MembersData> _dataFuture;
  String _query = '';
  String _roleFilter = _allRoles;

  static const String _allRoles = 'All Roles';

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_MembersData> _load() async {
    final members = await _service.fetchMembers();
    bool canManage;
    if (widget.canManage != null) {
      canManage = widget.canManage!;
    } else {
      final me = await _service.fetchCurrentMember();
      final role = me?.role.toLowerCase();
      canManage = role == 'owner' || role == 'admin';
    }
    return _MembersData(members: members, canManage: canManage);
  }

  void _reload() {
    setState(() {
      _dataFuture = _load();
    });
  }

  List<ClinicMember> _applyFilters(List<ClinicMember> members) {
    return members
        .where((m) {
          if (_roleFilter != _allRoles &&
              m.role.toLowerCase() != _roleFilter.toLowerCase()) {
            return false;
          }
          if (_query.isEmpty) return true;
          return m.fullName.toLowerCase().contains(_query) ||
              m.roleLabel.toLowerCase().contains(_query) ||
              (m.phone ?? '').toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  Future<void> _editMember(ClinicMember member) async {
    final fullNameController = TextEditingController(text: member.fullName);
    final phoneController = TextEditingController(text: member.phone ?? '');
    var selectedRole = member.role.isNotEmpty
        ? member.role
        : ClinicRole.vet.value;
    var selectedStatus = member.accountStatus.isNotEmpty
        ? member.accountStatus
        : 'active';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ModernDialog(
          icon: LucideIcons.userCog,
          accent: AppColors.primaryDeep,
          title: 'Edit Member',
          subtitle: member.fullName.isNotEmpty
              ? 'Update details for ${member.fullName}.'
              : 'Update this member\'s profile.',
          width: 460,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModernField(
                label: 'FULL NAME',
                icon: LucideIcons.user,
                child: CustomTextField(
                  controller: fullNameController,
                  hintText: 'Full name',
                ),
              ),
              ModernField(
                label: 'PHONE',
                icon: LucideIcons.phone,
                child: CustomTextField(
                  controller: phoneController,
                  hintText: '+1 555 000 0000',
                  keyboardType: TextInputType.phone,
                ),
              ),
              ModernField(
                label: 'ROLE',
                icon: LucideIcons.shieldUser,
                child: CustomDropdownField<String>(
                  items: ClinicRole.values
                      .map((role) => role.value)
                      .toList(),
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
              ),
              ModernField(
                label: 'ACCOUNT STATUS',
                icon: LucideIcons.circleDot,
                child: CustomDropdownField<String>(
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
              ),
            ],
          ),
          footer: Row(
            children: [
              Expanded(
                child: PrimaryOutlinedButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'Save Changes',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
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
        if (!mounted) return;
        AppToast.success(context, 'Member updated.');
        _reload();
      } catch (e) {
        if (!mounted) return;
        AppToast.error(context, e.toString());
      }
    }
  }

  Future<void> _toggleBan(ClinicMember member) async {
    final isBlocked = member.accountStatus.toLowerCase() == 'blocked';
    final actionLabel = isBlocked ? 'Unblock' : 'Block';
    final nextStatus = isBlocked ? 'active' : 'blocked';

    final accent = isBlocked ? AppColors.stockIn : AppColors.error;
    final heroIcon = isBlocked
        ? LucideIcons.shieldCheck
        : LucideIcons.shieldAlert;
    final displayName = member.fullName.isNotEmpty
        ? member.fullName
        : 'this user';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ModernDialog(
          icon: heroIcon,
          accent: accent,
          title: '$actionLabel $displayName?',
          subtitle: isBlocked
              ? 'They will immediately regain access to the clinic.'
              : 'They will lose access to the clinic right away.',
          width: 440,
          body: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isBlocked ? LucideIcons.info : LucideIcons.triangleAlert,
                  size: 16,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBlocked
                        ? 'Unblocking restores login and all role permissions for this account.'
                        : 'Blocking signs the user out and prevents future sign-ins until restored.',
                    style: AppFonts.regular(
                      fontSize: 12.5,
                      color: AppColors.slate700,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          footer: Row(
            children: [
              Expanded(
                child: PrimaryOutlinedButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isBlocked ? LucideIcons.shieldCheck : LucideIcons.ban,
                          size: 16,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          actionLabel,
                          style: AppFonts.semiBold(
                            fontSize: 13,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _service.updateMember(
        memberId: member.id,
        accountStatus: nextStatus,
      );
      if (!mounted) return;
      AppToast.success(
        context,
        isBlocked ? 'User unblocked.' : 'User blocked.',
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  Future<void> _resetPassword(ClinicMember member) async {
    final passwordController = TextEditingController();
    final displayName = member.fullName.isNotEmpty
        ? member.fullName
        : 'this user';

    final newPassword = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        var visible = false;
        return StatefulBuilder(
          builder: (context, setInner) {
                return ModernDialog(
                  icon: LucideIcons.keyRound,
                  accent: AppColors.amberStock,
                  title: 'Reset Password',
                  subtitle: 'Issue a new password for $displayName.',
                  width: 440,
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: AppColors.amber50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.amber200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.triangleAlert,
                              size: 16,
                              color: AppColors.amber700,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'The user will be signed out of all sessions. Share the new password securely.',
                                style: AppFonts.regular(
                                  fontSize: 12.5,
                                  color: AppColors.amber900,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ModernField(
                        label: 'NEW PASSWORD',
                        icon: LucideIcons.lock,
                        helper: 'Minimum 8 characters.',
                        child: CustomTextField(
                          controller: passwordController,
                          hintText: 'Enter a strong password',
                          obscureText: !visible,
                          suffixIcon: IconButton(
                            splashRadius: 18,
                            icon: Icon(
                              visible ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 16,
                              color: AppColors.slate400,
                            ),
                            onPressed: () =>
                                setInner(() => visible = !visible),
                          ),
                        ),
                      ),
                    ],
                  ),
                  footer: Row(
                    children: [
                      Expanded(
                        child: PrimaryOutlinedButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          text: 'Reset Password',
                          onPressed: () {
                            if (passwordController.text.trim().length < 8) {
                              AppToast.error(
                                context,
                                'Password must be at least 8 characters.',
                              );
                              return;
                            }
                            Navigator.of(
                              context,
                            ).pop(passwordController.text);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
      },
    );

    if (newPassword == null || newPassword.isEmpty) return;

    try {
      await _service.resetMemberPassword(
        memberId: member.id,
        newPassword: newPassword,
      );
      if (!mounted) return;
      AppToast.success(context, 'Password reset.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return FutureBuilder<_MembersData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final canManage = data?.canManage ?? false;

        return Scaffold(
          backgroundColor: isMobile ? AppColors.white : AppColors.bgCanvas,
          floatingActionButton: (isMobile && canManage)
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  onPressed: () async {
                    final created = await AddMemberDialog.show(context);
                    if (created) _reload();
                  },
                  child: const Icon(LucideIcons.plus, color: Colors.white),
                )
              : null,
          appBar: (isMobile && widget.showAppBar)
              ? CustomAppBar(
                  title: 'User Management',
                  trailing: IconButton(
                    onPressed: _reload,
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                  ),
                )
              : null,
          body: PageContent(
            maxWidth: isMobile ? 800 : 1200,
            fillHeight: true,
            child: SafeArea(
              child: isMobile
                  ? _buildMobileBody(context, snapshot)
                  : _buildWebBody(context, snapshot),
            ),
          ),
        );
      },
    );
  }

  // ── Mobile (unchanged) ────────────────────────────────────────────────────
  Widget _buildMobileBody(
    BuildContext context,
    AsyncSnapshot<_MembersData> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(
        child: Text('Failed to load members.', style: AppFonts.regular()),
      );
    }

    final data = snapshot.data;
    final members = data?.members ?? const [];
    final canManage = data?.canManage ?? false;

    if (members.isEmpty) {
      return Center(
        child: Text('No members found.', style: AppFonts.regular()),
      );
    }

    return Column(
      children: [
        if (!widget.showAppBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text('User Management', style: AppFonts.semiBold(fontSize: 18)),
                const Spacer(),
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, _) => 12.height,
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
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
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
                    if (canManage) ...[
                      8.width,
                      IconButton(
                        onPressed: () => _editMember(member),
                        icon: const Icon(LucideIcons.squarePen, size: 18),
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Web ───────────────────────────────────────────────────────────────────
  Widget _buildWebBody(
    BuildContext context,
    AsyncSnapshot<_MembersData> snapshot,
  ) {
    final isLoading = snapshot.connectionState == ConnectionState.waiting;
    final data = snapshot.data;
    final members = data?.members ?? const <ClinicMember>[];
    final canManage = data?.canManage ?? false;
    final filtered = _applyFilters(members);

    final stats = _MemberStats.from(members);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WebHeader(
          memberCount: members.length,
          canManage: canManage,
          onRefresh: _reload,
          onAdd: () async {
            final created = await AddMemberDialog.show(context);
            if (created) _reload();
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
          child: _StatsRow(stats: stats),
        ),
        _FilterBar(
          searchController: _searchController,
          roleFilter: _roleFilter,
          onRoleChanged: (value) => setState(() => _roleFilter = value),
          filteredCount: filtered.length,
          totalCount: members.length,
        ),
        Expanded(
          child: _buildWebContent(
            isLoading: isLoading,
            hasError: snapshot.hasError,
            allMembers: members,
            filtered: filtered,
            canManage: canManage,
          ),
        ),
      ],
    );
  }

  Widget _buildWebContent({
    required bool isLoading,
    required bool hasError,
    required List<ClinicMember> allMembers,
    required List<ClinicMember> filtered,
    required bool canManage,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError) {
      return Center(
        child: Text('Failed to load members.', style: AppFonts.regular()),
      );
    }
    if (allMembers.isEmpty) {
      return const _WebEmptyState(
        title: 'No team members yet',
        subtitle: 'Invite your first colleague to start collaborating.',
      );
    }
    if (filtered.isEmpty) {
      return const _WebEmptyState(
        title: 'No matches',
        subtitle: 'Try a different search or clear the role filter.',
      );
    }

    final itemCount = filtered.length + 1; // header + rows
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: const _TableHeaderRow(),
            ),
          );
        }
        final member = filtered[index - 1];
        final isLast = index == filtered.length;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  )
                : null,
            border: isLast
                ? Border.all(color: AppColors.border)
                : const Border(
                    left: BorderSide(color: AppColors.border),
                    right: BorderSide(color: AppColors.border),
                    bottom: BorderSide(color: AppColors.borderFaint),
                  ),
          ),
          child: _MemberRow(
            member: member,
            canManage: canManage,
            isLast: isLast,
            onEdit: () => _editMember(member),
            onBanToggle: () => _toggleBan(member),
            onResetPassword: () => _resetPassword(member),
          ),
        );
      },
    );
  }
}

class _MembersData {
  final List<ClinicMember> members;
  final bool canManage;
  const _MembersData({required this.members, required this.canManage});
}

class _MemberStats {
  final int total;
  final int active;
  final int blocked;

  const _MemberStats({
    required this.total,
    required this.active,
    required this.blocked,
  });

  factory _MemberStats.from(List<ClinicMember> list) {
    int active = 0, blocked = 0;
    for (final m in list) {
      final s = m.accountStatus.toLowerCase();
      if (s == 'active') {
        active++;
      } else if (s == 'blocked') {
        blocked++;
      }
    }
    return _MemberStats(total: list.length, active: active, blocked: blocked);
  }
}

// ── Web header ──────────────────────────────────────────────────────────────
class _WebHeader extends StatelessWidget {
  const _WebHeader({
    required this.memberCount,
    required this.canManage,
    required this.onRefresh,
    required this.onAdd,
  });

  final int memberCount;
  final bool canManage;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'User Management',
                  style: AppFonts.extraBold(
                    fontSize: 30,
                    color: AppColors.slate900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage clinic staff, roles, and access in one place.',
                  style: AppFonts.regular(
                    fontSize: 13,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.slate600,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (canManage) ...[
            const SizedBox(width: 10),
            PrimaryOutlinedButton(
              text: 'Invite Member',
              icon: LucideIcons.userPlus,
              onPressed: onAdd,
              fullWidth: false,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stats row ───────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final _MemberStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Users',
            value: stats.total.toString(),
            accent: AppColors.primaryDeep,
            icon: LucideIcons.users,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Active',
            value: stats.active.toString(),
            accent: AppColors.stockIn,
            icon: LucideIcons.circleCheck,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Blocked',
            value: stats.blocked.toString(),
            accent: AppColors.error,
            icon: LucideIcons.ban,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.medium(
                    fontSize: 11,
                    color: AppColors.slate500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppFonts.extraBold(
                    fontSize: 22,
                    color: AppColors.slate900,
                    letterSpacing: -0.5,
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

// ── Filter bar ──────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.roleFilter,
    required this.onRoleChanged,
    required this.filteredCount,
    required this.totalCount,
  });

  final TextEditingController searchController;
  final String roleFilter;
  final ValueChanged<String> onRoleChanged;
  final int filteredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final roles = <String>[
      'All Roles',
      ...ClinicRole.values.map((r) => r.label),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: CustomTextField(
              controller: searchController,
              hintText: 'Search by name, role, or phone…',
              prefixIcon: const Icon(
                LucideIcons.search,
                size: 16,
                color: AppColors.slate400,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final role in roles)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _RoleChip(
                        label: role,
                        selected: role == roleFilter,
                        onTap: () => onRoleChanged(role),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$filteredCount of $totalCount',
            style: AppFonts.medium(fontSize: 12, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.tintBlueBg : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppFonts.semiBold(
            fontSize: 12,
            color: selected ? AppColors.primary : AppColors.slate700,
          ),
        ),
      ),
    );
  }
}

// ── Table ───────────────────────────────────────────────────────────────────
class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  static const _headerStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.slate500,
    letterSpacing: 0.6,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: const [
          Expanded(flex: 4, child: Text('MEMBER', style: _headerStyle)),
          Expanded(flex: 3, child: Text('USERNAME', style: _headerStyle)),
          Expanded(flex: 2, child: Text('ROLE', style: _headerStyle)),
          Expanded(flex: 2, child: Text('STATUS', style: _headerStyle)),
          Expanded(flex: 3, child: Text('PHONE', style: _headerStyle)),
          SizedBox(width: 132),
        ],
      ),
    );
  }
}

class _MemberRow extends StatefulWidget {
  const _MemberRow({
    required this.member,
    required this.canManage,
    required this.isLast,
    required this.onEdit,
    required this.onBanToggle,
    required this.onResetPassword,
  });

  final ClinicMember member;
  final bool canManage;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onBanToggle;
  final VoidCallback onResetPassword;

  @override
  State<_MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends State<_MemberRow> {
  bool _hovered = false;
  bool _usernameVisible = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final borderRadius = widget.isLast
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(11),
            bottomRight: Radius.circular(11),
          )
        : BorderRadius.zero;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: widget.canManage ? widget.onEdit : null,
        onHover: (hovering) {
          if (_hovered == hovering) return;
          setState(() => _hovered = hovering);
        },
        hoverColor: AppColors.slate50,
        splashColor: AppColors.primaryDeep.withValues(alpha: 0.06),
        highlightColor: AppColors.primaryDeep.withValues(alpha: 0.03),
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _Avatar(name: m.fullName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.fullName.isNotEmpty ? m.fullName : 'Unnamed user',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID · ${m.id.length > 8 ? m.id.substring(0, 8) : m.id}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: _UsernameCell(
                  username: m.username,
                  revealed: _usernameVisible,
                  onToggle: () =>
                      setState(() => _usernameVisible = !_usernameVisible),
                ),
              ),
              Expanded(
                flex: 2,
                child: _RoleBadge(role: m.role, label: m.roleLabel),
              ),
              Expanded(flex: 2, child: _StatusPill(label: m.statusLabel)),
              Expanded(
                flex: 3,
                child: Text(
                  (m.phone == null || m.phone!.trim().isEmpty) ? '—' : m.phone!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.slate500,
                  ),
                ),
              ),
              SizedBox(
                width: 132,
                child: widget.canManage
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _RowAction(
                            icon: LucideIcons.keyRound,
                            tooltip: 'Reset password',
                            onTap: widget.onResetPassword,
                            color: AppColors.slate500,
                          ),
                          _RowAction(
                            icon: m.accountStatus.toLowerCase() == 'blocked'
                                ? LucideIcons.shieldCheck
                                : LucideIcons.ban,
                            tooltip: m.accountStatus.toLowerCase() == 'blocked'
                                ? 'Unblock'
                                : 'Block',
                            onTap: widget.onBanToggle,
                            color: m.accountStatus.toLowerCase() == 'blocked'
                                ? AppColors.stockIn
                                : AppColors.error,
                          ),
                          _RowAction(
                            icon: LucideIcons.squarePen,
                            tooltip: 'Edit',
                            onTap: widget.onEdit,
                            color: _hovered
                                ? AppColors.primaryDeep
                                : AppColors.slate500,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  static const _palette = <List<Color>>[
    [Color(0xFF2563EB), Color(0xFF1E40AF)],
    [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    [Color(0xFF0D9488), Color(0xFF134E4A)],
    [Color(0xFFD97706), Color(0xFFB45309)],
    [Color(0xFFDB2777), Color(0xFF9D174D)],
    [Color(0xFF0EA5E9), Color(0xFF075985)],
  ];

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'U';
    final seed = name.isEmpty
        ? 0
        : name.codeUnits.fold<int>(0, (a, b) => a + b) % _palette.length;
    final colors = _palette[seed];
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colors[1].withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppFonts.extraBold(fontSize: 14, color: AppColors.white),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.label});
  final String role;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = _roleColor(role);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: palette.dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.semiBold(fontSize: 11.5, color: palette.text),
            ),
          ],
        ),
      ),
    );
  }

  _RolePalette _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return const _RolePalette(
          bg: Color(0xFFF5F3FF),
          border: Color(0xFFDDD6FE),
          dot: Color(0xFF7C3AED),
          text: Color(0xFF5B21B6),
        );
      case 'admin':
        return const _RolePalette(
          bg: Color(0xFFEFF6FF),
          border: Color(0xFFBFDBFE),
          dot: Color(0xFF2563EB),
          text: Color(0xFF1E40AF),
        );
      case 'vet':
        return const _RolePalette(
          bg: Color(0xFFECFDF5),
          border: Color(0xFFA7F3D0),
          dot: Color(0xFF059669),
          text: Color(0xFF065F46),
        );
      case 'receptionist':
        return const _RolePalette(
          bg: Color(0xFFFFF7ED),
          border: Color(0xFFFED7AA),
          dot: Color(0xFFEA580C),
          text: Color(0xFF9A3412),
        );
      case 'assistant':
        return const _RolePalette(
          bg: Color(0xFFF1F5F9),
          border: Color(0xFFCBD5E1),
          dot: Color(0xFF475569),
          text: Color(0xFF334155),
        );
      default:
        return const _RolePalette(
          bg: AppColors.tintGreyBg,
          border: AppColors.border,
          dot: AppColors.slate500,
          text: AppColors.slate700,
        );
    }
  }
}

class _RolePalette {
  final Color bg;
  final Color border;
  final Color dot;
  final Color text;
  const _RolePalette({
    required this.bg,
    required this.border,
    required this.dot,
    required this.text,
  });
}

// ── Empty state ─────────────────────────────────────────────────────────────
class _WebEmptyState extends StatelessWidget {
  const _WebEmptyState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              LucideIcons.users,
              size: 26,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppFonts.semiBold(fontSize: 15, color: AppColors.slate700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.regular(fontSize: 13, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}

// ── Username cell with eye toggle ───────────────────────────────────────────
class _UsernameCell extends StatelessWidget {
  const _UsernameCell({
    required this.username,
    required this.revealed,
    required this.onToggle,
  });

  final String? username;
  final bool revealed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final hasValue = username != null && username!.trim().isNotEmpty;
    final display = !hasValue
        ? '—'
        : (revealed ? username! : '•' * username!.length.clamp(4, 12));
    return Row(
      children: [
        Expanded(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: AppColors.slate700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (hasValue)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                revealed ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 14,
                color: AppColors.slate400,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Row action button ──────────────────────────────────────────────────────
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ── Status pill (shared) ────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final isActive = normalized.contains('active');
    final isBlocked = normalized.contains('blocked');
    final color = isActive
        ? AppColors.stockIn
        : isBlocked
        ? AppColors.error
        : AppColors.amberStock;
    final bg = isActive
        ? AppColors.stockInBg
        : isBlocked
        ? const Color(0xFFFEF2F2)
        : AppColors.amber50;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppFonts.semiBold(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
