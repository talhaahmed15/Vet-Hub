import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/models/client.dart';
import 'package:clinic_management_app/models/pet.dart';
import 'package:clinic_management_app/services/appointment_service.dart';

// Events
sealed class OwnerPetsEvent {
  const OwnerPetsEvent();
}

final class OwnersRequested extends OwnerPetsEvent {
  const OwnersRequested();
}

final class PetsRequested extends OwnerPetsEvent {
  const PetsRequested(this.clientId);

  final String clientId;
}

// States
sealed class OwnerPetsState {
  const OwnerPetsState();
}

final class OwnerPetsInitial extends OwnerPetsState {
  const OwnerPetsInitial();
}

final class OwnerPetsLoading extends OwnerPetsState {
  const OwnerPetsLoading();
}

final class OwnerPetsLoaded extends OwnerPetsState {
  const OwnerPetsLoaded({
    required this.clients,
    required this.pets,
    required this.petsLoading,
    required this.petsClientId,
  });

  final List<Client> clients;
  final List<Pet> pets;
  final bool petsLoading;
  final String? petsClientId;

  OwnerPetsLoaded copyWith({
    List<Client>? clients,
    List<Pet>? pets,
    bool? petsLoading,
    String? petsClientId,
  }) {
    return OwnerPetsLoaded(
      clients: clients ?? this.clients,
      pets: pets ?? this.pets,
      petsLoading: petsLoading ?? this.petsLoading,
      petsClientId: petsClientId ?? this.petsClientId,
    );
  }
}

final class OwnerPetsFailure extends OwnerPetsState {
  const OwnerPetsFailure(this.message);

  final String message;
}

class OwnerPetsBloc extends Bloc<OwnerPetsEvent, OwnerPetsState> {
  OwnerPetsBloc()
    : _appointmentService = AppointmentService(),
      super(const OwnerPetsInitial()) {
    on<OwnersRequested>(_onOwnersRequested);
    on<PetsRequested>(_onPetsRequested);
  }

  final AppointmentService _appointmentService;

  Future<void> _onOwnersRequested(
    OwnersRequested event,
    Emitter<OwnerPetsState> emit,
  ) async {
    emit(const OwnerPetsLoading());
    try {
      final clients = await _appointmentService.fetchClients();
      emit(
        OwnerPetsLoaded(
          clients: clients,
          pets: const [],
          petsLoading: false,
          petsClientId: null,
        ),
      );
    } catch (error) {
      emit(OwnerPetsFailure('Failed to load clients: $error'));
    }
  }

  Future<void> _onPetsRequested(
    PetsRequested event,
    Emitter<OwnerPetsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OwnerPetsLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        petsLoading: true,
        petsClientId: event.clientId,
      ),
    );

    try {
      final pets = await _appointmentService.fetchPetsByClientId(
        event.clientId,
      );
      emit(
        currentState.copyWith(
          pets: pets,
          petsLoading: false,
          petsClientId: event.clientId,
        ),
      );
    } catch (error) {
      emit(OwnerPetsFailure('Failed to load pets for client: $error'));
    }
  }
}
