class AppointmentFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? species;
  final String? billingStatus;
  final String? veterinarianId;

  const AppointmentFilters({
    this.startDate,
    this.endDate,
    this.species,
    this.billingStatus,
    this.veterinarianId,
  });

  AppointmentFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? species,
    String? billingStatus,
    String? veterinarianId,
  }) {
    return AppointmentFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      species: species ?? this.species,
      billingStatus: billingStatus ?? this.billingStatus,
      veterinarianId: veterinarianId ?? this.veterinarianId,
    );
  }

  bool get hasDateRange => startDate != null && endDate != null;
}
