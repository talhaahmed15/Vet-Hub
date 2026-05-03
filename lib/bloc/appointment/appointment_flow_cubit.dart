import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/models/client.dart';
import 'package:clinic_management_app/models/pet.dart';
import 'package:clinic_management_app/services/appointment_service.dart';

class PrescriptionDraft {
  final String name;
  final String dosage;
  final String instructions;

  const PrescriptionDraft({
    required this.name,
    required this.dosage,
    required this.instructions,
  });
}

enum AppointmentSaveStatus { idle, saving, success, failure }

class AppointmentFlowState {
  final String? clientId;
  final String ownerName;
  final String ownerPhone;
  final bool isNewPet;
  final String? petId;
  final String petName;
  final String petSpecies;
  final String petBreed;
  final String petAge;
  final String temperature;
  final String weightKg;
  final String heartRate;
  final String appointmentReason;
  final String conditionStatus;
  final String conditionNotes;
  final List<PrescriptionDraft> prescriptions;
  final AppointmentSaveStatus saveStatus;
  final String? saveError;
  final String? appointmentId;

  const AppointmentFlowState({
    this.clientId,
    this.ownerName = '',
    this.ownerPhone = '',
    this.isNewPet = true,
    this.petId,
    this.petName = '',
    this.petSpecies = '',
    this.petBreed = '',
    this.petAge = '',
    this.temperature = '',
    this.weightKg = '',
    this.heartRate = '',
    this.appointmentReason = '',
    this.conditionStatus = '',
    this.conditionNotes = '',
    this.prescriptions = const [],
    this.saveStatus = AppointmentSaveStatus.idle,
    this.saveError,
    this.appointmentId,
  });

  AppointmentFlowState copyWith({
    String? clientId,
    String? ownerName,
    String? ownerPhone,
    bool? isNewPet,
    String? petId,
    String? petName,
    String? petSpecies,
    String? petBreed,
    String? petAge,
    String? temperature,
    String? weightKg,
    String? heartRate,
    String? appointmentReason,
    String? conditionStatus,
    String? conditionNotes,
    List<PrescriptionDraft>? prescriptions,
    AppointmentSaveStatus? saveStatus,
    String? saveError,
    String? appointmentId,
  }) {
    return AppointmentFlowState(
      clientId: clientId ?? this.clientId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      isNewPet: isNewPet ?? this.isNewPet,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      petSpecies: petSpecies ?? this.petSpecies,
      petBreed: petBreed ?? this.petBreed,
      petAge: petAge ?? this.petAge,
      temperature: temperature ?? this.temperature,
      weightKg: weightKg ?? this.weightKg,
      heartRate: heartRate ?? this.heartRate,
      appointmentReason: appointmentReason ?? this.appointmentReason,
      conditionStatus: conditionStatus ?? this.conditionStatus,
      conditionNotes: conditionNotes ?? this.conditionNotes,
      prescriptions: prescriptions ?? this.prescriptions,
      saveStatus: saveStatus ?? this.saveStatus,
      saveError: saveError,
      appointmentId: appointmentId ?? this.appointmentId,
    );
  }
}

class AppointmentFlowCubit extends Cubit<AppointmentFlowState> {
  AppointmentFlowCubit({AppointmentService? appointmentService})
    : _appointmentService = appointmentService ?? AppointmentService(),
      super(const AppointmentFlowState());

  final AppointmentService _appointmentService;

  void initializeFromStart({
    required String ownerName,
    required String ownerPhone,
    String? clientId,
    required bool isNewPet,
    String? petId,
    required String petName,
    required String petSpecies,
    required String petBreed,
    required String petAge,
    required String temperature,
    required String weightKg,
    required String heartRate,
    required String appointmentReason,
  }) {
    emit(
      state.copyWith(
        clientId: clientId,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        isNewPet: isNewPet,
        petId: petId,
        petName: petName,
        petSpecies: petSpecies,
        petBreed: petBreed,
        petAge: petAge,
        temperature: temperature,
        weightKg: weightKg,
        heartRate: heartRate,
        appointmentReason: appointmentReason,
        appointmentId: null,
        saveStatus: AppointmentSaveStatus.idle,
        saveError: null,
      ),
    );
  }

  void updateCondition({required String status, required String notes}) {
    emit(
      state.copyWith(
        conditionStatus: status,
        conditionNotes: notes,
      ),
    );
  }

  void addPrescription(PrescriptionDraft draft) {
    final updated = List<PrescriptionDraft>.from(state.prescriptions)
      ..add(draft);
    emit(state.copyWith(prescriptions: updated));
  }

  void removePrescription(int index) {
    if (index < 0 || index >= state.prescriptions.length) return;
    final updated = List<PrescriptionDraft>.from(state.prescriptions)
      ..removeAt(index);
    emit(state.copyWith(prescriptions: updated));
  }

  Future<void> completeAppointment() async {
    if (state.saveStatus == AppointmentSaveStatus.saving) {
      return;
    }

    if (state.ownerName.trim().isEmpty) {
      emit(
        state.copyWith(
          saveStatus: AppointmentSaveStatus.failure,
          saveError: 'Owner name is required.',
        ),
      );
      return;
    }

    if (state.petName.trim().isEmpty) {
      emit(
        state.copyWith(
          saveStatus: AppointmentSaveStatus.failure,
          saveError: 'Pet name is required.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(saveStatus: AppointmentSaveStatus.saving, saveError: null),
    );

    try {
      String clientId = state.clientId ?? '';
      if (clientId.isEmpty) {
        final client = await _appointmentService.createClient(
          fullName: state.ownerName,
          phone: state.ownerPhone,
        );
        clientId = client.id;
      }

      String petId = state.petId ?? '';
      if (state.isNewPet || petId.isEmpty) {
        final pet = await _appointmentService.createPet(
          clientId: clientId,
          name: state.petName,
          species: state.petSpecies,
          breed: state.petBreed,
        );
        petId = pet.id;
      }

      final prescriptions = state.prescriptions
          .map(
            (rx) => {
              'name': rx.name,
              'dosage': rx.dosage,
              'instructions': rx.instructions,
            },
          )
          .toList(growable: false);

      final appointmentId = await _appointmentService.createAppointment(
        clientId: clientId,
        petId: petId,
        appointmentReason: state.appointmentReason,
        conditionStatus: state.conditionStatus,
        conditionNotes: state.conditionNotes,
        temperature: state.temperature,
        weightKg: state.weightKg,
        heartRate: state.heartRate,
        prescriptions: prescriptions,
      );

      emit(
        state.copyWith(
          clientId: clientId,
          petId: petId,
          appointmentId: appointmentId,
          saveStatus: AppointmentSaveStatus.success,
          saveError: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          saveStatus: AppointmentSaveStatus.failure,
          saveError: 'Failed to save appointment: $error',
        ),
      );
    }
  }
}
