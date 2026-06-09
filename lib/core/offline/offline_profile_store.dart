import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';

/// Perfil offline de un usuario. No incluye contraseña.
class OfflineAuthProfile {
  const OfflineAuthProfile({
    required this.userId,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.departamentoId,
    this.token,
    required this.fechaUltimoLogin,
    this.offlineEnabled = true,
  });

  final String userId;
  final String nombre;
  final String correo;
  final String rol;
  final String? departamentoId;
  final String? token;
  final DateTime fechaUltimoLogin;
  final bool offlineEnabled;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userId': userId,
    'nombre': nombre,
    'correo': correo,
    'rol': rol,
    'departamentoId': departamentoId,
    'token': token,
    'fechaUltimoLogin': fechaUltimoLogin.toIso8601String(),
    'offlineEnabled': offlineEnabled,
  };

  factory OfflineAuthProfile.fromJson(Map<String, dynamic> json) {
    return OfflineAuthProfile(
      userId: json['userId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
      departamentoId: json['departamentoId'] as String?,
      token: json['token'] as String?,
      fechaUltimoLogin: json['fechaUltimoLogin'] != null
          ? DateTime.tryParse(json['fechaUltimoLogin'] as String? ?? '') ?? DateTime.now()
          : DateTime.now(),
      offlineEnabled: json['offlineEnabled'] as bool? ?? true,
    );
  }
}

/// Store para perfiles offline — indexados por correo (lowercase).
class OfflineProfileStore {
  OfflineProfileStore(this._box);

  final Box<String> _box;

  static String _key(String correo) => correo.trim().toLowerCase();

  /// Guarda o actualiza el perfil offline de un usuario.
  /// NUNCA guarda contraseña.
  Future<void> saveProfile(OfflineAuthProfile profile) async {
    final String key = _key(profile.correo);
    await _box.put(key, jsonEncode(profile.toJson()));
    developer.log(
      '[OFFLINE][PROFILE] Saved profile correo=${profile.correo} userId=${profile.userId}',
      name: 'OfflineProfileStore',
    );
  }

  /// Recupera el perfil offline por correo. Retorna null si no existe.
  OfflineAuthProfile? getProfile(String correo) {
    final String? raw = _box.get(_key(correo));
    if (raw == null || raw.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return OfflineAuthProfile.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Lista todos los perfiles offline disponibles.
  List<OfflineAuthProfile> getAllProfiles() {
    final List<OfflineAuthProfile> result = <OfflineAuthProfile>[];
    for (final String key in _box.keys.cast<String>()) {
      final String? raw = _box.get(key);
      if (raw == null) continue;
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          result.add(OfflineAuthProfile.fromJson(decoded));
        }
      } catch (_) {}
    }
    return result;
  }

  /// Retorna true si existe un perfil offline para el correo dado.
  bool hasProfile(String correo) => _box.containsKey(_key(correo));
}
