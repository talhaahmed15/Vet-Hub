class AddItemState {
  final bool isSubmitting;
  final bool submitSuccess;
  final String? error;

  const AddItemState({
    this.isSubmitting = false,
    this.submitSuccess = false,
    this.error,
  });

  static const _unset = Object();

  AddItemState copyWith({
    bool? isSubmitting,
    bool? submitSuccess,
    Object? error = _unset,
  }) {
    return AddItemState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      error: error == _unset ? this.error : error as String?,
    );
  }
}
