class ClinicAccountSignupState {
  final bool isSubmitting;
  final String? message;
  final String? error;
  final bool submitSuccess;

  const ClinicAccountSignupState({
    this.isSubmitting = false,
    this.message,
    this.error,
    this.submitSuccess = false,
  });

  static const _unset = Object();

  ClinicAccountSignupState copyWith({
    bool? isSubmitting,
    Object? message = _unset,
    Object? error = _unset,
    bool? submitSuccess,
  }) {
    return ClinicAccountSignupState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: message == _unset ? this.message : message as String?,
      error: error == _unset ? this.error : error as String?,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}
