class AppointmentPrescription {
  final String name;
  final String dosage;
  final String instructions;

  const AppointmentPrescription({
    required this.name,
    required this.dosage,
    required this.instructions,
  });

  factory AppointmentPrescription.fromMap(Map<String, dynamic> map) {
    return AppointmentPrescription(
      name: map['name']?.toString() ?? '',
      dosage: map['dosage']?.toString() ?? '',
      instructions: map['instructions']?.toString() ?? '',
    );
  }
}

class AppointmentDetail {
  final String id;
  final String clientId;
  final String petId;
  final String petName;
  final String petSpecies;
  final String petBreed;
  final String ownerName;
  final String ownerPhone;
  final String doctorName;
  final String appointmentReason;
  final String conditionStatus;
  final String conditionNotes;
  final String temperature;
  final String heartRate;
  final String weightKg;
  final DateTime createdAt;
  final List<AppointmentPrescription> prescriptions;

  const AppointmentDetail({
    required this.id,
    required this.clientId,
    required this.petId,
    required this.petName,
    required this.petSpecies,
    required this.petBreed,
    required this.ownerName,
    required this.ownerPhone,
    required this.doctorName,
    required this.appointmentReason,
    required this.conditionStatus,
    required this.conditionNotes,
    required this.temperature,
    required this.heartRate,
    required this.weightKg,
    required this.createdAt,
    required this.prescriptions,
  });

  factory AppointmentDetail.fromMap(Map<String, dynamic> map) {
    final client = (map['client'] as Map<String, dynamic>?) ?? const {};
    final pet = (map['pet'] as Map<String, dynamic>?) ?? const {};
    final doctor = (map['doctor'] as Map<String, dynamic>?) ?? const {};
    final createdRaw = map['created_at']?.toString() ?? '';
    final created =
        DateTime.tryParse(createdRaw)?.toLocal() ?? DateTime.now();

    final rx = (map['prescriptions'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .map(AppointmentPrescription.fromMap)
            .toList(growable: false) ??
        const <AppointmentPrescription>[];

    return AppointmentDetail(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      petId: map['pet_id']?.toString() ?? '',
      petName: pet['name']?.toString() ?? '',
      petSpecies: pet['species']?.toString() ?? '',
      petBreed: pet['breed']?.toString() ?? '',
      ownerName: client['full_name']?.toString() ?? '',
      ownerPhone: client['phone']?.toString() ?? '',
      doctorName: doctor['full_name']?.toString() ?? '',
      appointmentReason: map['appointment_reason']?.toString() ?? '',
      conditionStatus: map['condition_status']?.toString() ?? '',
      conditionNotes: map['condition_notes']?.toString() ?? '',
      temperature: map['temperature']?.toString() ?? '',
      heartRate: map['heart_rate']?.toString() ?? '',
      weightKg: map['weight_kg']?.toString() ?? '',
      createdAt: created,
      prescriptions: rx,
    );
  }
}
