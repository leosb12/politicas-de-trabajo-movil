import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
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
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _getCurrentSessionUseCase = getCurrentSessionUseCase,
       _logoutUseCase = logoutUseCase,
       super(LoginState.initial()) {
    _restoreSession();
  }

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetCurrentSessionUseCase _getCurrentSessionUseCase;
  final LogoutUseCase _logoutUseCase;

  Future<void> _restoreSession() async {
    try {
      final user = await _getCurrentSessionUseCase();
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
    state = state.copyWith(
      isLoading: true,
      isCheckingSession: false,
      clearError: true,
    );

    try {
      final user = await _loginUseCase(email: email, password: password);
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
        errorMessage: 'No se pudo iniciar sesion.',
        clearAuthenticatedUser: true,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _logoutUseCase();
      state = state.copyWith(
        isLoading: false,
        isCheckingSession: false,
        clearError: true,
        clearAuthenticatedUser: true,
      );
    } on ApiFailure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      );
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

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}