import '../../../../core/offline/offline_profile_store.dart';
import '../../../../core/storage/session_storage.dart';
import '../../domain/entities/authenticated_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/auth_offline_datasource.dart';
import '../datasource/auth_remote_datasource.dart';
import '../models/change_password_request_model.dart';
import '../models/forgot_password_request_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/reset_password_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SessionStorage sessionStorage,
    required OfflineProfileStore offlineProfileStore,
  })  : _remoteDataSource = remoteDataSource,
        _sessionStorage = sessionStorage,
        _offlineDataSource = AuthOfflineDataSource(offlineProfileStore);

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStorage _sessionStorage;
  final AuthOfflineDataSource _offlineDataSource;

  @override
  Future<AuthenticatedUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequestModel(correo: email.trim(), password: password),
    );

    final AuthenticatedUser user = response.toEntity();

    // Guardar sesión y perfil offline (sin contraseña)
    await _sessionStorage.saveSession(user.toJson());

    return user;
  }

  @override
  Future<AuthenticatedUser> loginOffline({required String correo}) async {
    return _offlineDataSource.loginOffline(correo.trim());
  }

  @override
  bool hasOfflineProfile({required String correo}) {
    return _offlineDataSource.hasOfflineProfile(correo.trim());
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
  Future<void> changePassword({
    required String correo,
    required String passwordActual,
    required String nuevaContrasena,
    required String confirmarNuevaContrasena,
  }) {
    return _remoteDataSource.changePassword(
      ChangePasswordRequestModel(
        correo: correo.trim(),
        passwordActual: passwordActual,
        nuevaContrasena: nuevaContrasena,
        confirmarNuevaContrasena: confirmarNuevaContrasena,
      ),
    );
  }

  @override
  Future<void> forgotPassword({required String email}) {
    return _remoteDataSource.forgotPassword(
      ForgotPasswordRequestModel(email: email.trim()),
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _remoteDataSource.resetPassword(
      ResetPasswordRequestModel(
        token: token.trim(),
        newPassword: newPassword,
      ),
    );
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
    // Nota: NO borramos el perfil offline al cerrar sesión
    // para que el usuario pueda volver a entrar sin internet
  }
}
