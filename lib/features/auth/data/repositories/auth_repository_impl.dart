import '../../../../core/storage/session_storage.dart';
import '../../domain/entities/authenticated_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/auth_remote_datasource.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SessionStorage sessionStorage,
  }) : _remoteDataSource = remoteDataSource,
       _sessionStorage = sessionStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStorage _sessionStorage;

  @override
  Future<AuthenticatedUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequestModel(correo: email.trim(), password: password),
    );

    final AuthenticatedUser user = response.toEntity();
    await _sessionStorage.saveSession(user.toJson());
    return user;
  }

  @override
  Future<AuthenticatedUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final String normalizedEmail = email.trim();

    await _remoteDataSource.register(
      RegisterRequestModel(
        nombre: name.trim(),
        correo: normalizedEmail,
        password: password,
      ),
    );

    final response = await _remoteDataSource.login(
      LoginRequestModel(correo: normalizedEmail, password: password),
    );

    final AuthenticatedUser user = response.toEntity();
    await _sessionStorage.saveSession(user.toJson());
    return user;
  }

  @override
  Future<AuthenticatedUser?> getPersistedSession() async {
    final Map<String, dynamic>? session = _sessionStorage.readSession();
    if (session == null) {
      return null;
    }

    return AuthenticatedUser.fromJson(session);
  }

  @override
  Future<void> clearSession() async {
    await _sessionStorage.clearSession();
  }
}
