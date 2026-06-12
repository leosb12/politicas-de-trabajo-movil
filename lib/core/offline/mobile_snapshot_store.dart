import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';

import 'offline_hive_store.dart';

/// Store para snapshots de datos de la app (trámites, seguimientos, tareas).
/// Todas las claves están separadas por userId.
class MobileSnapshotStore {
  MobileSnapshotStore(this._box);

  final Box<String> _box;

  // ── Keys ──────────────────────────────────────────────────────────────────

  static String _tramitesDisponiblesKey(String userId) =>
      '${userId}_tramitesDisponibles';

  static String _misTramitesKey(String userId) =>
      '${userId}_misTramites';

  static String _seguimientoKey(String userId, String instanciaId) =>
      '${userId}_seguimiento_$instanciaId';

  static String _tareaDetalleKey(String userId, String tareaId) =>
      '${userId}_tareaDetalle_$tareaId';

  static String _formDraftKey(String userId, String tareaId) =>
      '${userId}_formDraft_$tareaId';

  static String _lastSyncKey(String userId) =>
      '${userId}_lastSync';

  // ── Trámites disponibles ──────────────────────────────────────────────────

  Future<void> saveTramitesDisponibles(String userId, List<dynamic> list) async {
    await OfflineHiveStore.putJson(_box, _tramitesDisponiblesKey(userId), list);
    developer.log('[SNAPSHOT] Saved tramitesDisponibles count=${list.length}', name: 'MobileSnapshotStore');
  }

  List<dynamic>? getTramitesDisponibles(String userId) {
    final dynamic raw = OfflineHiveStore.getJson(_box, _tramitesDisponiblesKey(userId));
    if (raw is List) return raw;
    return null;
  }

  // ── Mis Trámites ──────────────────────────────────────────────────────────

  Future<void> saveMisTramites(String userId, List<dynamic> list) async {
    await OfflineHiveStore.putJson(_box, _misTramitesKey(userId), list);
    developer.log('[SNAPSHOT] Saved misTramites count=${list.length}', name: 'MobileSnapshotStore');
  }

  List<dynamic>? getMisTramites(String userId) {
    final dynamic raw = OfflineHiveStore.getJson(_box, _misTramitesKey(userId));
    if (raw is List) return raw;
    return null;
  }

  /// Agrega un trámite creado offline a la lista local.
  Future<void> addTramiteOffline(String userId, Map<String, dynamic> tramite) async {
    final List<dynamic> existing = getMisTramites(userId) ?? <dynamic>[];
    // Evitar duplicados por id local
    final String localId = tramite['id']?.toString() ?? '';
    existing.removeWhere((dynamic t) => t is Map && t['id']?.toString() == localId);
    existing.insert(0, tramite);
    await saveMisTramites(userId, existing);
  }

  /// Reemplaza un trámite por su localId con datos del servidor (id real).
  Future<void> resolveTramiteLocalId({
    required String userId,
    required String localId,
    required Map<String, dynamic> realData,
  }) async {
    final List<dynamic> existing = getMisTramites(userId) ?? <dynamic>[];
    final int idx = existing.indexWhere(
      (dynamic t) => t is Map && t['id']?.toString() == localId,
    );
    if (idx >= 0) {
      final Map<dynamic, dynamic> localItem = existing[idx] as Map;

      // Extraer datos del objeto anidado si es InicioInstanciaResponse
      Map<String, dynamic> instMap = <String, dynamic>{};
      String? realNombre;
      if (realData.containsKey('instancia') && realData['instancia'] is Map) {
        instMap = Map<String, dynamic>.from(realData['instancia'] as Map);
        realNombre = realData['politicaNombre']?.toString();
      } else {
        instMap = realData;
      }

      final String realId = instMap['id']?.toString() ?? instMap['instanciaId']?.toString() ?? '';
      if (realId.isEmpty) {
        developer.log(
          '[SNAPSHOT] Warning: resolveTramiteLocalId called but realId is empty',
          name: 'MobileSnapshotStore',
        );
        return;
      }

      // Fusionar y normalizar la información para la visualización del card
      final Map<String, dynamic> resolvedCard = <String, dynamic>{
        'id': realId,
        'usuarioId': instMap['creadaPor']?.toString() ?? instMap['usuarioId']?.toString() ?? userId,
        'codigoTramite': instMap['codigoTramite']?.toString() ?? 'EN_CURSO',
        'nombre': realNombre ?? instMap['nombre']?.toString() ?? localItem['nombre']?.toString() ?? 'Trámite',
        'estado': instMap['estadoInstancia']?.toString() ?? instMap['estado']?.toString() ?? 'EN_CURSO',
        'estadoInstancia': instMap['estadoInstancia']?.toString() ?? instMap['estado']?.toString() ?? 'EN_CURSO',
        'progreso': instMap['progreso'] ?? instMap['porcentaje'] ?? 0.0,
        'porcentaje': instMap['porcentaje'] ?? instMap['progreso'] ?? 0,
        'fechaCreacion': instMap['fechaCreacion']?.toString() ?? localItem['fechaCreacion']?.toString() ?? DateTime.now().toIso8601String(),
        'esOffline': false,
      };

      existing[idx] = resolvedCard;
      await saveMisTramites(userId, existing);
      developer.log('[SNAPSHOT] Resolved localId=$localId → realId=$realId', name: 'MobileSnapshotStore');

      // Migrar el seguimiento cacheado local del localId al realId
      final Map<String, dynamic>? localSeg = getSeguimiento(userId, localId);
      if (localSeg != null) {
        localSeg['instanciaId'] = realId;
        localSeg['codigoTramite'] = resolvedCard['codigoTramite'];
        localSeg['estadoInstancia'] = resolvedCard['estadoInstancia'];
        localSeg['esOffline'] = false;

        await saveSeguimiento(userId, realId, localSeg);
        await _box.delete(_seguimientoKey(userId, localId));
        developer.log('[SNAPSHOT] Migrated local seguimiento localId=$localId → realId=$realId', name: 'MobileSnapshotStore');
      }
    }
  }

  // ── Seguimiento ───────────────────────────────────────────────────────────

  Future<void> saveSeguimiento(
    String userId,
    String instanciaId,
    Map<String, dynamic> data,
  ) async {
    await OfflineHiveStore.putJson(_box, _seguimientoKey(userId, instanciaId), data);
    developer.log('[SNAPSHOT] Saved seguimiento instanciaId=$instanciaId', name: 'MobileSnapshotStore');
  }

  Map<String, dynamic>? getSeguimiento(String userId, String instanciaId) {
    final dynamic raw = OfflineHiveStore.getJson(_box, _seguimientoKey(userId, instanciaId));
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  // ── Tarea Detalle ─────────────────────────────────────────────────────────

  Future<void> saveTareaDetalle(
    String userId,
    String tareaId,
    Map<String, dynamic> data,
  ) async {
    await OfflineHiveStore.putJson(_box, _tareaDetalleKey(userId, tareaId), data);
    developer.log('[SNAPSHOT] Saved tareaDetalle tareaId=$tareaId', name: 'MobileSnapshotStore');
  }

  Map<String, dynamic>? getTareaDetalle(String userId, String tareaId) {
    final dynamic raw = OfflineHiveStore.getJson(_box, _tareaDetalleKey(userId, tareaId));
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  // ── Form Draft ────────────────────────────────────────────────────────────

  Future<void> saveFormDraft(
    String userId,
    String tareaId,
    Map<String, dynamic> draft,
  ) async {
    await OfflineHiveStore.putJson(_box, _formDraftKey(userId, tareaId), draft);
    developer.log('[SNAPSHOT] Saved formDraft tareaId=$tareaId', name: 'MobileSnapshotStore');
  }

  Map<String, dynamic>? getFormDraft(String userId, String tareaId) {
    final dynamic raw = OfflineHiveStore.getJson(_box, _formDraftKey(userId, tareaId));
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  Future<void> clearFormDraft(String userId, String tareaId) async {
    await _box.delete(_formDraftKey(userId, tareaId));
  }

  // ── Last Sync timestamp ────────────────────────────────────────────────────

  Future<void> saveLastSync(String userId) async {
    await _box.put(_lastSyncKey(userId), DateTime.now().toIso8601String());
  }

  DateTime? getLastSync(String userId) {
    final String? raw = _box.get(_lastSyncKey(userId));
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── Utilidad ──────────────────────────────────────────────────────────────

  bool hasData(String userId) {
    return _box.containsKey(_misTramitesKey(userId)) ||
        _box.containsKey(_tramitesDisponiblesKey(userId));
  }

  // ── Catálogo dinámico completo de políticas ───────────────────────────────

  static String _catalogoPoliticasKey(String userId) =>
      '${userId}_catalogoPoliticas';

  Future<void> saveCatalogoPoliticas(String userId, List<dynamic> list) async {
    await OfflineHiveStore.putJson(_box, _catalogoPoliticasKey(userId), list);
    developer.log('[SNAPSHOT] Saved catalogoPoliticas count=${list.length}', name: 'MobileSnapshotStore');
  }

  List<dynamic>? getCatalogoPoliticas(String userId) {
    final dynamic raw = OfflineHiveStore.getJson(_box, _catalogoPoliticasKey(userId));
    if (raw is List) return raw;
    return null;
  }

  // ── Borrar datos offline ──────────────────────────────────────────────────

  Future<void> clearOfflineData(String userId) async {
    // Borrar catálogo completo
    await _box.delete(_catalogoPoliticasKey(userId));
    // Borrar catálogo ligero de trámites disponibles
    await _box.delete(_tramitesDisponiblesKey(userId));
    // Borrar timestamp de sincronización
    await _box.delete(_lastSyncKey(userId));
    
    // Borrar seguimientos y detalles de procesos/tareas individuales
    final List<String> keysToDelete = <String>[];
    for (final dynamic key in _box.keys) {
      final String keyStr = key.toString();
      if (keyStr.startsWith('${userId}_seguimiento_') ||
          keyStr.startsWith('${userId}_tareaDetalle_') ||
          keyStr.startsWith('${userId}_formDraft_') ||
          keyStr.startsWith('${userId}_politicaDetalle_')) {
        keysToDelete.add(keyStr);
      }
    }
    for (final String key in keysToDelete) {
      await _box.delete(key);
    }
    developer.log('[SNAPSHOT] Cleared all offline data for userId=$userId', name: 'MobileSnapshotStore');
  }
}
