class PasswordRecoveryState {
  const PasswordRecoveryState({
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
  });

  factory PasswordRecoveryState.initial() {
    return const PasswordRecoveryState(
      isLoading: false,
      errorMessage: null,
      successMessage: null,
    );
  }

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  bool get isSuccess => successMessage != null;

  PasswordRecoveryState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return PasswordRecoveryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}
