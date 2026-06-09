import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../../core/network/api_failure.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/offline/offline_initial_sync_service.dart';
import '../../domain/entities/authenticated_user.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_current_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'login_state.dart';

class AuthViewModel extends StateNotifier<LoginState> {
  AuthViewModel({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetCurrentSessionUseCase getCurrentSessionUseCase,
    required LogoutUseCase logoutUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required PushNotificationService pushNotificationService,
    required OfflineInitialSyncService offlineInitialSyncService,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _getCurrentSessionUseCase = getCurrentSessionUseCase,
        _logoutUseCase = logoutUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        _pushNotificationService = pushNotificationService,
        _offlineInitialSyncService = offlineInitialSyncService,
        _authRepository = authRepository,
        super(LoginState.initial()) {
    _pushNotificationService.initialize();
    _restoreSession();
  }

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetCurrentSessionUseCase _getCurrentSessionUseCase;
  final LogoutUseCase _logoutUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final PushNotificationService _pushNotificationService;
  final OfflineInitialSyncService _offlineInitialSyncService;
  final AuthRepository _authRepository;

  Future<void> _restoreSession() async {
    try {
      final user = await _getCurrentSessionUseCase();
      if (user != null) {
        await _pushNotificationService.syncForUser(user);
      }
      state = state.copyWith(
        isCheckingSession: false,
        authenticatedUser: user,
        clearAuthenticatedUser: user == null,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isCheckingSession: false,
        clearAuthenticatedUser: true,
        clearError: true,
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    developer.log('[AUTH][VM] login started email=${email.trim()}', name: 'AuthViewModel');
    state = state.copyWith(
      isLoading: true,
      isCheckingSession: false,
      clearError: true,
      isOfflineSession: false,
    );

    try {
      // Intento de login ONLINE
      final user = await _loginUseCase(email: email, password: password);
      await _pushNotificationService.syncForUser(user);

      developer.log('[AUTH][VM] login online success userId=${user.id}', name: 'AuthViewModel');
      state = state.copyWith(
        isLoading: false,
        authenticatedUser: user,
        clearError: true,
        isOfflineSession: false,
        isSyncingInitial: true,
        offlineSyncMessage: 'Preparando modo offline...',
      );

      // Sincronización inicial en background
      _runInitialSync(user);
    } on ApiFailure catch (failure) {
      developer.log(
        '[AUTH][VM] login api failure: ${failure.message} status=${failure.statusCode}',
        name: 'AuthViewModel',
      );

      // Si es un error de red/conexión → intentar login offline
      if (_isConnectionError(failure)) {
        developer.log('[AUTH][VM] Connection error — attempting offline login', name: 'AuthViewModel');
        await _tryOfflineLogin(email: email);
      } else {
        // Error de credenciales u otro → no permitir offline
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          clearAuthenticatedUser: true,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        '[AUTH][VM] login unexpected failure error=$error',
        name: 'AuthViewModel',
        error: error,
        stackTrace: stackTrace,
      );
      // Intento offline también para errores inesperados de red
      await _tryOfflineLogin(email: email);
    }
  }

  Future<void> _tryOfflineLogin({required String email}) async {
    try {
      final user = await _authRepository.loginOffline(correo: email.trim());

      developer.log(
        '[AUTH][VM] Offline login success userId=${user.id}',
        name: 'AuthViewModel',
      );

      state = state.copyWith(
        isLoading: false,
        authenticatedUser: user,
        clearError: true,
        isOfflineSession: true,
        offlineSyncReady: true,
        offlineSyncMessage: 'Modo offline — usando datos guardados',
      );
    } on ApiFailure catch (offlineFailure) {
      developer.log(
        '[AUTH][VM] Offline login failed: ${offlineFailure.message}',
        name: 'AuthViewModel',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: offlineFailure.message,
        clearAuthenticatedUser: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo iniciar sesión.',
        clearAuthenticatedUser: true,
      );
    }
  }

  /// Ejecuta la sincronización inicial post-login en background.
  void _runInitialSync(AuthenticatedUser user) {
    _offlineInitialSyncService
        .syncAfterLogin(
      userId: user.id,
      nombre: user.nombre,
      correo: user.correo,
      rol: user.rol,
      departamentoId: user.departamentoId,
      token: user.token,
    )
        .then((SyncResult result) {
      developer.log(
        '[AUTH][VM] Initial sync done: success=${result.success} message=${result.message}',
        name: 'AuthViewModel',
      );
      if (mounted) {
        state = state.copyWith(
          isSyncingInitial: false,
          offlineSyncReady: result.success,
          offlineSyncMessage: result.message,
        );
      }
    }).catchError((Object e) {
      developer.log('[AUTH][VM] Initial sync error: $e', name: 'AuthViewModel');
      if (mounted) {
        state = state.copyWith(
          isSyncingInitial: false,
          offlineSyncMessage: 'No se pudo preparar el modo offline',
        );
      }
    });
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _logoutUseCase();
      _pushNotificationService.clearAuthenticatedUser();
      state = state.copyWith(
        isLoading: false,
        isCheckingSession: false,
        clearError: true,
        clearAuthenticatedUser: true,
        isOfflineSession: false,
        offlineSyncReady: false,
        isSyncingInitial: false,
        clearOfflineSyncMessage: true,
      );
    } on ApiFailure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cerrar sesion.',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isCheckingSession: false,
      clearError: true,
    );

    try {
      final user = await _registerUseCase(
        name: name,
        email: email,
        password: password,
      );
      await _pushNotificationService.syncForUser(user);

      state = state.copyWith(
        isLoading: false,
        authenticatedUser: user,
        clearError: true,
        isSyncingInitial: true,
        offlineSyncMessage: 'Preparando modo offline...',
      );

      _runInitialSync(user);
    } on ApiFailure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        clearAuthenticatedUser: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo crear la cuenta.',
        clearAuthenticatedUser: true,
      );
    }
  }

  Future<bool> changePassword({
    required String correo,
    required String passwordActual,
    required String nuevaContrasena,
    required String confirmarNuevaContrasena,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _changePasswordUseCase(
        correo: correo,
        passwordActual: passwordActual,
        nuevaContrasena: nuevaContrasena,
        confirmarNuevaContrasena: confirmarNuevaContrasena,
      );

      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on ApiFailure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cambiar la contrasena.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  bool _isConnectionError(ApiFailure failure) {
    final String msg = failure.message.toLowerCase();
    return failure.statusCode == null ||
        msg.contains('conexion') ||
        msg.contains('timeout') ||
        msg.contains('connect') ||
        msg.contains('network') ||
        msg.contains('red');
  }
}
