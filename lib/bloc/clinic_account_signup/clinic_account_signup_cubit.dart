import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/bloc/clinic_account_signup/clinic_account_signup_state.dart';
import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:clinic_management_app/services/clinic_account_service.dart';

class ClinicAccountSignupCubit extends Cubit<ClinicAccountSignupState> {
  ClinicAccountSignupCubit({ClinicAccountService? service})
    : _service = service ?? ClinicAccountService(),
      super(const ClinicAccountSignupState());

  final ClinicAccountService _service;

  Future<void> submitAccount({
    required String clinicCode,
    required String fullName,
    required String username,
    required String password,
    required ClinicRole role,
    String? phone,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    emit(state.copyWith(isSubmitting: true, message: null, error: null));
    try {
      await _service.createClinicAccount(
        clinicCode: clinicCode,
        fullName: fullName,
        username: username.trim(),
        password: password,
        role: role,
        phone: phone,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          submitSuccess: true,
          message: "Account created successfully",
        ),
      );
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }
}
