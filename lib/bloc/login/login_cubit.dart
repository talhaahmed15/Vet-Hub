import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/bloc/login/login_state.dart';
import 'package:clinic_management_app/services/auth_service.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(LoginInitial());

  final AuthService _authService;

  Future<void> login({
    required String clinicCode,
    required String username,
    required String password,
    String? clinicId,
  }) async {
    try {
      emit(LoginLoading());
      final result = await _authService.loginWithUsername(
        clinicCode: clinicCode,
        username: username,
        password: password,
        clinicId: clinicId,
      );
      emit(LoginSuccess(result.status));
    } catch (e) {
      log(e.toString());
      emit(LoginFailure(e.toString()));
    }
  }
}
