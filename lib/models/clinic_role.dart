enum ClinicRole { owner, admin, vet, receptionist, assistant }

extension ClinicRoleLabel on ClinicRole {
  String get label {
    switch (this) {
      case ClinicRole.owner:
        return 'Owner';
      case ClinicRole.admin:
        return 'Admin';
      case ClinicRole.vet:
        return 'Veterinarian';
      case ClinicRole.receptionist:
        return 'Receptionist';
      case ClinicRole.assistant:
        return 'Assistant';
    }
  }

  String get value => name;
}
