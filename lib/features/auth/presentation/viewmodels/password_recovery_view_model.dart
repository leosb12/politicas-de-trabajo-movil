import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import 'password_recovery_state.dart';

class PasswordRecoveryViewModel extends StateNotifier<PasswordRecoveryState> {
  PasswordRecoveryViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(PasswordRecoveryState.initial());

  final AuthRepository _authRepository;

  Future<void> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    
    try {
      await _authRepository.forgotPassword(email: email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Revisa tu correo para recuperar tu contraseña',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    
    try {
      await _authRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Tu contraseña ha sido restablecida correctamente',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}
