import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../../core/network/api_failure.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_current_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'login_state.dart';

class AuthViewModel extends StateNotifier<LoginState> {
  AuthViewModel({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetCurrentSessionUseCase getCurrentSessionUseCase,
    required LogoutUseCase logoutUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required PushNotificationService pushNotificationService,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _getCurrentSessionUseCase = getCurrentSessionUseCase,
       _logoutUseCase = logoutUseCase,
       _changePasswordUseCase = changePasswordUseCase,
       _pushNotificationService = pushNotificationService,
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

  Future<void> _restoreSession() async {
    try {
      final user = await _getCurrentSessionUseCase();
      await _pushNotificationService.syncForUser(user);
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
    developer.log(
      '[AUTH][VM] login started email=${email.trim()}',
      name: 'AuthViewModel',
    );
    print('[AUTH][VM] login started email=${email.trim()}');
    state = state.copyWith(
      isLoading: true,
      isCheckingSession: false,
      clearError: true,
    );

    try {
      final user = await _loginUseCase(email: email, password: password);
      await _pushNotificationService.syncForUser(user);
      developer.log(
        '[AUTH][VM] login success userId=${user.id}',
        name: 'AuthViewModel',
      );
      print('[AUTH][VM] login success userId=${user.id}');
      state = state.copyWith(
        isLoading: false,
        authenticatedUser: user,
        clearError: true,
      );
    } on ApiFailure catch (failure) {
      developer.log(
        '[AUTH][VM] login api failure message=${failure.message}',
        name: 'AuthViewModel',
      );
      print('[AUTH][VM] login api failure message=${failure.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        clearAuthenticatedUser: true,
      );
    } catch (error, stackTrace) {
      developer.log(
        '[AUTH][VM] login unexpected failure error=$error',
        name: 'AuthViewModel',
        error: error,
        stackTrace: stackTrace,
      );
      print('[AUTH][VM] login unexpected failure error=$error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo iniciar sesion.',
        clearAuthenticatedUser: true,
      );
    }
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
      );
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
}
