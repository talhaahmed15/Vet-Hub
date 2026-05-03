class ClinicUser {
  final String id;
  final String fullName;

  const ClinicUser({required this.id, required this.fullName});

  factory ClinicUser.fromMap(Map<String, dynamic> map) {
    return ClinicUser(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
    );
  }
}
