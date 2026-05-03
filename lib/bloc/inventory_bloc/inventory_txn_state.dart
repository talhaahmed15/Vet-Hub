class InventoryTxnState {
  final bool isSubmitting;
  final bool submitSuccess;
  final String? error;

  const InventoryTxnState({
    this.isSubmitting = false,
    this.submitSuccess = false,
    this.error,
  });

  static const _unset = Object();

  InventoryTxnState copyWith({
    bool? isSubmitting,
    bool? submitSuccess,
    Object? error = _unset,
  }) {
    return InventoryTxnState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      error: error == _unset ? this.error : error as String?,
    );
  }
}
