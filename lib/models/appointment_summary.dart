class AppointmentSummary {
  final String id;
  final String clientId;
  final String petName;
  final String petSpecies;
  final String petBreed;
  final String ownerName;
  final String ownerPhone;
  final String appointmentReason;
  final String conditionStatus;
  final String conditionNotes;
  final String temperature;
  final String heartRate;
  final String weightKg;
  final DateTime createdAt;

  const AppointmentSummary({
    required this.id,
    required this.clientId,
    required this.petName,
    required this.petSpecies,
    required this.petBreed,
    required this.ownerName,
    required this.ownerPhone,
    required this.appointmentReason,
    required this.conditionStatus,
    required this.conditionNotes,
    required this.temperature,
    required this.heartRate,
    required this.weightKg,
    required this.createdAt,
  });

  factory AppointmentSummary.fromMap(Map<String, dynamic> map) {
    final pet = (map['pet'] as Map<String, dynamic>?) ?? const {};
    final client = (map['client'] as Map<String, dynamic>?) ?? const {};
    final createdRaw = map['created_at']?.toString() ?? '';
    final created =
        DateTime.tryParse(createdRaw)?.toLocal() ?? DateTime.now();

    return AppointmentSummary(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      petName: pet['name']?.toString() ?? '',
      petSpecies: pet['species']?.toString() ?? '',
      petBreed: pet['breed']?.toString() ?? '',
      ownerName: client['full_name']?.toString() ?? '',
      ownerPhone: client['phone']?.toString() ?? '',
      appointmentReason: map['appointment_reason']?.toString() ?? '',
      conditionStatus: map['condition_status']?.toString() ?? '',
      conditionNotes: map['condition_notes']?.toString() ?? '',
      temperature: map['temperature']?.toString() ?? '',
      heartRate: map['heart_rate']?.toString() ?? '',
      weightKg: map['weight_kg']?.toString() ?? '',
      createdAt: created,
    );
  }

  AppointmentSummary copyWith({
    String? ownerName,
    String? ownerPhone,
  }) {
    return AppointmentSummary(
      id: id,
      clientId: clientId,
      petName: petName,
      petSpecies: petSpecies,
      petBreed: petBreed,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      appointmentReason: appointmentReason,
      conditionStatus: conditionStatus,
      conditionNotes: conditionNotes,
      temperature: temperature,
      heartRate: heartRate,
      weightKg: weightKg,
      createdAt: createdAt,
    );
  }
}
