import '../../domain/entities/authenticated_user.dart';

class LoginState {
  const LoginState({
    required this.isLoading,
    required this.isCheckingSession,
    required this.errorMessage,
    required this.authenticatedUser,
    this.isOfflineSession = false,
    this.offlineSyncReady = false,
    this.isSyncingInitial = false,
    this.offlineSyncMessage,
  });

  factory LoginState.initial() {
    return const LoginState(
      isLoading: false,
      isCheckingSession: true,
      errorMessage: null,
      authenticatedUser: null,
      isOfflineSession: false,
      offlineSyncReady: false,
      isSyncingInitial: false,
    );
  }

  final bool isLoading;
  final bool isCheckingSession;
  final String? errorMessage;
  final AuthenticatedUser? authenticatedUser;

  /// true si la sesión actual es offline (sin token válido del servidor).
  final bool isOfflineSession;

  /// true después de que la sincronización inicial completó exitosamente.
  final bool offlineSyncReady;

  /// true mientras se ejecuta la sincronización inicial post-login.
  final bool isSyncingInitial;

  /// Mensaje descriptivo de la sincronización (ej: "Modo offline listo").
  final String? offlineSyncMessage;

  bool get isAuthenticated => authenticatedUser != null;

  LoginState copyWith({
    bool? isLoading,
    bool? isCheckingSession,
    String? errorMessage,
    bool clearError = false,
    AuthenticatedUser? authenticatedUser,
    bool clearAuthenticatedUser = false,
    bool? isOfflineSession,
    bool? offlineSyncReady,
    bool? isSyncingInitial,
    String? offlineSyncMessage,
    bool clearOfflineSyncMessage = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      authenticatedUser: clearAuthenticatedUser
          ? null
          : (authenticatedUser ?? this.authenticatedUser),
      isOfflineSession: isOfflineSession ?? this.isOfflineSession,
      offlineSyncReady: offlineSyncReady ?? this.offlineSyncReady,
      isSyncingInitial: isSyncingInitial ?? this.isSyncingInitial,
      offlineSyncMessage: clearOfflineSyncMessage
          ? null
          : (offlineSyncMessage ?? this.offlineSyncMessage),
    );
  }
}
