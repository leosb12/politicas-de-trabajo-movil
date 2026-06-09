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
      existing[idx] = realData;
      await saveMisTramites(userId, existing);
      developer.log('[SNAPSHOT] Resolved localId=$localId → realId=${realData['id']}', name: 'MobileSnapshotStore');
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
}
