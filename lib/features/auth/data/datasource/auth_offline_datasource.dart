import 'dart:developer' as developer;

import '../../../../core/network/api_failure.dart';
import '../../../../core/offline/offline_profile_store.dart';
import '../../domain/entities/authenticated_user.dart';

/// Datasource para login offline usando perfiles previamente sincronizados.
class AuthOfflineDataSource {
  AuthOfflineDataSource(this._profileStore);

  final OfflineProfileStore _profileStore;

  /// Realiza login offline con un correo previamente sincronizado.
  /// No requiere contraseña — la autenticación fue validada online previamente.
  ///
  /// Lanza [ApiFailure] si no existe perfil offline para el correo.
  Future<AuthenticatedUser> loginOffline(String correo) async {
    developer.log(
      '[AUTH][OFFLINE] Attempting offline login correo=$correo',
      name: 'AuthOfflineDataSource',
    );

    final OfflineAuthProfile? profile = _profileStore.getProfile(correo);

    if (profile == null) {
      developer.log(
        '[AUTH][OFFLINE] No offline profile found for correo=$correo',
        name: 'AuthOfflineDataSource',
      );
      throw ApiFailure(
        message: 'No se encontró perfil offline para este correo. '
            'Primero debes iniciar sesión con internet para activar el modo offline.',
      );
    }

    developer.log(
      '[AUTH][OFFLINE] Offline login success userId=${profile.userId} correo=${profile.correo}',
      name: 'AuthOfflineDataSource',
    );

    return AuthenticatedUser(
      id: profile.userId,
      nombre: profile.nombre,
      correo: profile.correo,
      rol: profile.rol,
      departamentoId: profile.departamentoId,
      token: profile.token, // Token puede estar expirado — solo para datos locales
    );
  }

  /// Retorna true si existe un perfil offline para el correo dado.
  bool hasOfflineProfile(String correo) => _profileStore.hasProfile(correo);
}
