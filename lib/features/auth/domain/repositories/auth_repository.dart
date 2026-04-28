import '../entities/authenticated_user.dart';

abstract class AuthRepository {
  Future<AuthenticatedUser> login({
    required String email,
    required String password,
  });

  Future<AuthenticatedUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> changePassword({
    required String correo,
    required String passwordActual,
    required String nuevaContrasena,
    required String confirmarNuevaContrasena,
  });

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<AuthenticatedUser?> getPersistedSession();

  Future<void> clearSession();
}
