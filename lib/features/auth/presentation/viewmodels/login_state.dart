import '../../domain/entities/authenticated_user.dart';

class LoginState {
  const LoginState({
    required this.isLoading,
    required this.isCheckingSession,
    required this.errorMessage,
    required this.authenticatedUser,
  });

  factory LoginState.initial() {
    return const LoginState(
      isLoading: false,
      isCheckingSession: true,
      errorMessage: null,
      authenticatedUser: null,
    );
  }

  final bool isLoading;
  final bool isCheckingSession;
  final String? errorMessage;
  final AuthenticatedUser? authenticatedUser;

  bool get isAuthenticated => authenticatedUser != null;

  LoginState copyWith({
    bool? isLoading,
    bool? isCheckingSession,
    String? errorMessage,
    bool clearError = false,
    AuthenticatedUser? authenticatedUser,
    bool clearAuthenticatedUser = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      authenticatedUser: clearAuthenticatedUser
          ? null
          : (authenticatedUser ?? this.authenticatedUser),
    );
  }
}
