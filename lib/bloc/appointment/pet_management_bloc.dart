import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/models/pet.dart';
import 'package:clinic_management_app/services/appointment_service.dart';

sealed class PetManagementEvent {
  const PetManagementEvent();
}

final class PetManagementLoad extends PetManagementEvent {
  const PetManagementLoad(this.clientId);

  final String clientId;
}

final class PetManagementCreate extends PetManagementEvent {
  const PetManagementCreate({
    required this.clientId,
    required this.name,
    required this.species,
    this.breed,
  });

  final String clientId;
  final String name;
  final String species;
  final String? breed;
}

final class PetManagementUpdate extends PetManagementEvent {
  const PetManagementUpdate({
    required this.petId,
    required this.name,
    required this.species,
    this.breed,
  });

  final String petId;
  final String name;
  final String species;
  final String? breed;
}

final class PetManagementDelete extends PetManagementEvent {
  const PetManagementDelete(this.petId);

  final String petId;
}

sealed class PetManagementState {
  const PetManagementState();
}

final class PetManagementInitial extends PetManagementState {
  const PetManagementInitial();
}

final class PetManagementLoading extends PetManagementState {
  const PetManagementLoading();
}

final class PetManagementLoaded extends PetManagementState {
  const PetManagementLoaded({
    required this.clientId,
    required this.pets,
    this.isSubmitting = false,
    this.error,
  });

  final String clientId;
  final List<Pet> pets;
  final bool isSubmitting;
  final String? error;

  PetManagementLoaded copyWith({
    List<Pet>? pets,
    bool? isSubmitting,
    String? error,
  }) {
    return PetManagementLoaded(
      clientId: clientId,
      pets: pets ?? this.pets,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

final class PetManagementFailure extends PetManagementState {
  const PetManagementFailure(this.message);

  final String message;
}

class PetManagementBloc extends Bloc<PetManagementEvent, PetManagementState> {
  PetManagementBloc({AppointmentService? appointmentService})
    : _appointmentService = appointmentService ?? AppointmentService(),
      super(const PetManagementInitial()) {
    on<PetManagementLoad>(_onLoad);
    on<PetManagementCreate>(_onCreate);
    on<PetManagementUpdate>(_onUpdate);
    on<PetManagementDelete>(_onDelete);
  }

  final AppointmentService _appointmentService;

  Future<void> _onLoad(
    PetManagementLoad event,
    Emitter<PetManagementState> emit,
  ) async {
    emit(const PetManagementLoading());
    try {
      final pets = await _appointmentService.fetchPetsByClientId(
        event.clientId,
      );
      emit(PetManagementLoaded(clientId: event.clientId, pets: pets));
    } catch (e) {
      emit(PetManagementFailure('Failed to load pets: $e'));
    }
  }

  Future<void> _onCreate(
    PetManagementCreate event,
    Emitter<PetManagementState> emit,
  ) async {
    final current = state;
    if (current is! PetManagementLoaded) return;
    emit(current.copyWith(isSubmitting: true, error: null));
    try {
      final pet = await _appointmentService.createPet(
        clientId: event.clientId,
        name: event.name,
        species: event.species,
        breed: event.breed,
      );
      final updated = List<Pet>.from(current.pets)..add(pet);
      updated.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      emit(current.copyWith(pets: updated, isSubmitting: false));
    } catch (e) {
      emit(current.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> _onUpdate(
    PetManagementUpdate event,
    Emitter<PetManagementState> emit,
  ) async {
    final current = state;
    if (current is! PetManagementLoaded) return;
    emit(current.copyWith(isSubmitting: true, error: null));
    try {
      final pet = await _appointmentService.updatePet(
        petId: event.petId,
        name: event.name,
        species: event.species,
        breed: event.breed,
      );
      final updated = current.pets.map((entry) {
        if (entry.id == pet.id) return pet;
        return entry;
      }).toList(growable: false);
      emit(current.copyWith(pets: updated, isSubmitting: false));
    } catch (e) {
      emit(current.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> _onDelete(
    PetManagementDelete event,
    Emitter<PetManagementState> emit,
  ) async {
    final current = state;
    if (current is! PetManagementLoaded) return;
    emit(current.copyWith(isSubmitting: true, error: null));
    try {
      await _appointmentService.deletePet(event.petId);
      final updated = current.pets
          .where((entry) => entry.id != event.petId)
          .toList(growable: false);
      emit(current.copyWith(pets: updated, isSubmitting: false));
    } catch (e) {
      emit(current.copyWith(isSubmitting: false, error: e.toString()));
    }
  }
}
