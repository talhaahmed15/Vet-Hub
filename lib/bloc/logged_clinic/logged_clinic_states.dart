import 'package:clinic_management_app/models/clinic_model.dart';

abstract class LoggedClinicState {}

class LoggedClinicInitial extends LoggedClinicState {}

class LoggedClinicLoading extends LoggedClinicState {}

class LoggedClinicSuccess extends LoggedClinicState {
  final Clinic clinic;

  LoggedClinicSuccess(this.clinic);
}

class LoggedClinicFailure extends LoggedClinicState {
  final String message;

  LoggedClinicFailure(this.message);
}
