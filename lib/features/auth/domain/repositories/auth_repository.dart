import '../entities/authenticated_user.dart';

abstract class AuthRepository {
  Future<AuthenticatedUser> login({
    required String email,
    required String password,
  });

  /// Login offline usando un correo previamente sincronizado.
  /// No requiere contraseña. Lanza [ApiFailure] si no hay perfil offline.
  Future<AuthenticatedUser> loginOffline({required String correo});

  /// Retorna true si existe un perfil offline para el correo.
  bool hasOfflineProfile({required String correo});

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

