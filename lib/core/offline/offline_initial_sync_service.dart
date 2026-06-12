import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../network/network_constants.dart';
import 'mobile_snapshot_store.dart';
import 'offline_profile_store.dart';

/// Servicio de sincronización inicial.
/// Ejecutado después del login online para precargar datos offline.
class OfflineInitialSyncService {
  OfflineInitialSyncService({
    required Dio dio,
    required OfflineProfileStore profileStore,
    required MobileSnapshotStore snapshotStore,
  })  : _dio = dio,
        _profileStore = profileStore,
        _snapshotStore = snapshotStore;

  final Dio _dio;
  final OfflineProfileStore _profileStore;
  final MobileSnapshotStore _snapshotStore;

  bool _syncing = false;

  /// Precarga todos los datos necesarios para modo offline.
  /// Llamado automáticamente después del login online exitoso.
  Future<SyncResult> syncAfterLogin({
    required String userId,
    required String nombre,
    required String correo,
    required String rol,
    String? departamentoId,
    String? token,
  }) async {
    if (_syncing) {
      developer.log('[INIT_SYNC] Already syncing, skipping', name: 'OfflineInitialSyncService');
      return const SyncResult(success: false, message: 'Sincronización en progreso');
    }

    _syncing = true;
    developer.log('[INIT_SYNC] Starting initial sync for userId=$userId', name: 'OfflineInitialSyncService');

    int synced = 0;
    int errors = 0;

    try {
      // 1. Guardar perfil offline (sin contraseña)
      await _profileStore.saveProfile(OfflineAuthProfile(
        userId: userId,
        nombre: nombre,
        correo: correo,
        rol: rol,
        departamentoId: departamentoId,
        token: token,
        fechaUltimoLogin: DateTime.now(),
        offlineEnabled: true,
      ));

      // 2. Precargar trámites disponibles
      try {
        await _syncTramitesDisponibles(userId);
        synced++;
      } catch (e) {
        developer.log('[INIT_SYNC] Failed tramitesDisponibles: $e', name: 'OfflineInitialSyncService');
        errors++;
      }

      // 3. Precargar mis trámites
      List<Map<String, dynamic>> misTramitesRaw = <Map<String, dynamic>>[];
      try {
        misTramitesRaw = await _syncMisTramites(userId);
        synced++;
      } catch (e) {
        developer.log('[INIT_SYNC] Failed misTramites: $e', name: 'OfflineInitialSyncService');
        errors++;
      }

      // 4. Para cada trámite, precargar seguimiento + tareas
      for (final Map<String, dynamic> tramite in misTramitesRaw) {
        final String instanciaId = tramite['id']?.toString() ?? '';
        if (instanciaId.isEmpty) continue;

        try {
          await _syncSeguimiento(userId, instanciaId);
          synced++;
        } catch (e) {
          developer.log('[INIT_SYNC] Failed seguimiento instanciaId=$instanciaId: $e', name: 'OfflineInitialSyncService');
          errors++;
        }
      }

      // 5. Precargar tareas propias del usuario (desde los seguimientos cargados)
      await _syncTareasFromSeguimientos(userId, misTramitesRaw);

      // 6. Guardar timestamp de última sincronización
      await _snapshotStore.saveLastSync(userId);

      developer.log(
        '[INIT_SYNC] Completed synced=$synced errors=$errors',
        name: 'OfflineInitialSyncService',
      );

      return SyncResult(
        success: true,
        message: errors == 0
            ? 'Modo offline listo'
            : 'Sincronización parcial ($errors errores)',
        syncedItems: synced,
        errorCount: errors,
      );
    } catch (e, st) {
      developer.log(
        '[INIT_SYNC] Unexpected error: $e',
        name: 'OfflineInitialSyncService',
        error: e,
        stackTrace: st,
      );
      return SyncResult(success: false, message: 'Error en sincronización: $e');
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncTramitesDisponibles(String userId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      NetworkConstants.availableTramitesPath,
      options: Options(headers: <String, String>{'X-User-Id': userId}),
    );
    final dynamic data = response.data;
    final List<dynamic> list = _extractList(data);
    await _snapshotStore.saveTramitesDisponibles(userId, list);
    developer.log('[INIT_SYNC] tramitesDisponibles count=${list.length}', name: 'OfflineInitialSyncService');
  }

  Future<List<Map<String, dynamic>>> _syncMisTramites(String userId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      NetworkConstants.misTramitesCardsPath,
      queryParameters: const <String, dynamic>{'page': 0, 'size': 50},
      options: Options(headers: <String, String>{'X-User-Id': userId}),
    );

    final dynamic data = response.data;
    final List<dynamic> list = _extractList(data);
    await _snapshotStore.saveMisTramites(userId, list);
    developer.log('[INIT_SYNC] misTramites count=${list.length}', name: 'OfflineInitialSyncService');

    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _syncSeguimiento(String userId, String instanciaId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      NetworkConstants.instanciaFlujoPath(instanciaId),
      options: Options(headers: <String, String>{'X-User-Id': userId}),
    );
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      await _snapshotStore.saveSeguimiento(userId, instanciaId, data);
    }
    developer.log('[INIT_SYNC] seguimiento instanciaId=$instanciaId saved', name: 'OfflineInitialSyncService');
  }

  Future<void> _syncTareasFromSeguimientos(
    String userId,
    List<Map<String, dynamic>> tramites,
  ) async {
    // Recolectar tareaIds desde los seguimientos cacheados
    final Set<String> tareaIds = <String>{};

    for (final Map<String, dynamic> tramite in tramites) {
      final String instanciaId = tramite['id']?.toString() ?? '';
      if (instanciaId.isEmpty) continue;

      final Map<String, dynamic>? seguimiento =
          _snapshotStore.getSeguimiento(userId, instanciaId);
      if (seguimiento == null) continue;

      // Extraer tareas del seguimiento
      final dynamic tareasRaw = seguimiento['tareas'];
      if (tareasRaw is List) {
        for (final dynamic tarea in tareasRaw) {
          if (tarea is Map<String, dynamic>) {
            final String tareaId = tarea['id']?.toString() ?? '';
            if (tareaId.isNotEmpty) tareaIds.add(tareaId);
          }
        }
      }
    }

    developer.log('[INIT_SYNC] Syncing ${tareaIds.length} tareas', name: 'OfflineInitialSyncService');

    // Limitar para no saturar el backend
    final List<String> limited = tareaIds.take(30).toList();

    for (final String tareaId in limited) {
      try {
        final Response<dynamic> response = await _dio.get<dynamic>(
          NetworkConstants.tareaDetallePath(tareaId),
          options: Options(headers: <String, String>{'X-User-Id': userId}),
        );
        final dynamic data = response.data;
        if (data is Map<String, dynamic>) {
          await _snapshotStore.saveTareaDetalle(userId, tareaId, data);
        }
      } catch (e) {
        developer.log('[INIT_SYNC] Failed tareaDetalle tareaId=$tareaId: $e', name: 'OfflineInitialSyncService');
      }
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final dynamic content = data['content'];
      if (content is List) return content;
    }
    return <dynamic>[];
  }

  /// Sincronización manual completa: descarga catálogo (con flujos y requisitos),
  /// trámites personales, seguimientos y tareas.
  Future<SyncResult> syncCompleto({required String userId}) async {
    if (_syncing) {
      developer.log('[INIT_SYNC] Already syncing, skipping', name: 'OfflineInitialSyncService');
      return const SyncResult(success: false, message: 'Sincronización en progreso');
    }

    _syncing = true;
    developer.log('[INIT_SYNC] Starting full manual sync for userId=$userId', name: 'OfflineInitialSyncService');

    int synced = 0;
    int errors = 0;

    try {
      // 1. Sincronizar catálogo dinámico completo (políticas, requisitos, flujos)
      try {
        final Response<dynamic> response = await _dio.get<dynamic>(
          NetworkConstants.sincronizarCatalogPath,
          options: Options(headers: <String, String>{'X-User-Id': userId}),
        );
        final dynamic data = response.data;
        final List<dynamic> list = _extractList(data);

        // Guardar catálogo completo en caché
        await _snapshotStore.saveCatalogoPoliticas(userId, list);

        // Convertir y guardar en trámite disponibles para mantener compatibilidad con la vista
        final List<dynamic> tramitesDisponiblesCompat = list.map((dynamic p) {
          if (p is Map) {
            final Map<String, dynamic> map = Map<String, dynamic>.from(p);
            return <String, dynamic>{
              'id': map['id']?.toString() ?? '',
              'nombre': map['nombre']?.toString() ?? '',
              'descripcion': map['descripcion']?.toString() ?? '',
              'requierePago': map['requierePago'] as bool? ?? false,
              'tieneRequisitosIniciales': map['requisitosIniciales'] != null &&
                  (map['requisitosIniciales'] as List).isNotEmpty,
              'montoPago': map['montoPago'],
              'monedaPago': map['monedaPago']?.toString(),
              'descripcionPago': map['descripcionPago']?.toString(),
            };
          }
          return p;
        }).toList();

        await _snapshotStore.saveTramitesDisponibles(userId, tramitesDisponiblesCompat);
        synced++;
        developer.log('[INIT_SYNC] Saved catalog count=${list.length}', name: 'OfflineInitialSyncService');
      } catch (e) {
        developer.log('[INIT_SYNC] Failed full catalog sync: $e', name: 'OfflineInitialSyncService');
        errors++;
      }

      // 2. Sincronizar mis trámites (cards)
      List<Map<String, dynamic>> misTramitesRaw = <Map<String, dynamic>>[];
      try {
        misTramitesRaw = await _syncMisTramites(userId);
        synced++;
      } catch (e) {
        developer.log('[INIT_SYNC] Failed misTramites sync: $e', name: 'OfflineInitialSyncService');
        errors++;
      }

      // 3. Para cada trámite, precargar seguimiento + tareas
      for (final Map<String, dynamic> tramite in misTramitesRaw) {
        final String instanciaId = tramite['id']?.toString() ?? '';
        if (instanciaId.isEmpty) continue;

        try {
          await _syncSeguimiento(userId, instanciaId);
          synced++;
        } catch (e) {
          developer.log('[INIT_SYNC] Failed seguimiento instanciaId=$instanciaId: $e', name: 'OfflineInitialSyncService');
          errors++;
        }
      }

      // 4. Precargar tareas propias de los seguimientos
      await _syncTareasFromSeguimientos(userId, misTramitesRaw);

      // 5. Guardar timestamp de última sincronización
      await _snapshotStore.saveLastSync(userId);

      return SyncResult(
        success: errors == 0,
        message: errors == 0
            ? 'Catálogo y datos sincronizados correctamente.'
            : 'Sincronización parcial ($errors errores).',
        syncedItems: synced,
        errorCount: errors,
      );
    } catch (e, st) {
      developer.log(
        '[INIT_SYNC] Unexpected error in full sync: $e',
        name: 'OfflineInitialSyncService',
        error: e,
        stackTrace: st,
      );
      return SyncResult(success: false, message: 'Error en sincronización: $e');
    } finally {
      _syncing = false;
    }
  }
}

/// Resultado de la sincronización inicial.
class SyncResult {
  const SyncResult({
    required this.success,
    required this.message,
    this.syncedItems = 0,
    this.errorCount = 0,
  });

  final bool success;
  final String message;
  final int syncedItems;
  final int errorCount;
}
