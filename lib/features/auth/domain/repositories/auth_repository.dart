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

  Future<AuthenticatedUser?> getPersistedSession();

  Future<void> clearSession();
}
