import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_states.dart';
import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/services/clinic_service.dart';
import 'package:clinic_management_app/services/storage.dart';

class LoggedClinicCubit extends Cubit<LoggedClinicState> {
  LoggedClinicCubit() : super(LoggedClinicInitial());

  void createClinic(Clinic clinic) async {
    try {
      emit(LoggedClinicLoading());

      final createdClinic = await ClinicService().addClinic(clinic);

      if (createdClinic != null) {
        await Storage.saveClinic(createdClinic);
        emit(LoggedClinicSuccess(createdClinic));
      } else {
        throw "Error while Creating Clinic";
      }
    } catch (e) {
      log(e.toString());
      emit(LoggedClinicFailure(e.toString()));
    }
  }

  void getClinicByCode(String clinicCode) async {
    try {
      emit(LoggedClinicLoading());

      final clinic = await ClinicService().getClinicByCode(clinicCode);

      if (clinic != null) {
        await Storage.saveClinic(clinic);
        emit(LoggedClinicSuccess(clinic));
      } else {
        throw "Error while Fetching Clinic";
      }
    } catch (e) {
      log(e.toString());
      emit(LoggedClinicFailure(e.toString()));
    }
  }
}
