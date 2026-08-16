import 'package:clinic_management_app/models/clinic_role.dart';

class ClinicMember {
  final String id;
  final String fullName;
  final String role;
  final String accountStatus;
  final String? phone;
  final String? username;

  const ClinicMember({
    required this.id,
    required this.fullName,
    required this.role,
    required this.accountStatus,
    this.phone,
    this.username,
  });

  factory ClinicMember.fromMap(Map<String, dynamic> map) {
    return ClinicMember(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      accountStatus: map['account_status']?.toString() ?? '',
      phone: map['phone']?.toString(),
      username: map['username']?.toString(),
    );
  }

  String get roleLabel {
    final normalized = role.trim().toLowerCase();
    final roleEnum = ClinicRole.values.where((r) => r.value == normalized);
    if (roleEnum.isNotEmpty) {
      return roleEnum.first.label;
    }
    if (normalized.isEmpty) return 'Staff';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String get statusLabel {
    final normalized = accountStatus.trim().toLowerCase();
    if (normalized.isEmpty) return 'Unknown';
    if (normalized == 'under_review') return 'Under Review';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}
