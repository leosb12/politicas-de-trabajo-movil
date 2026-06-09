import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

import '../../../../core/network/network_constants.dart';
import '../../../../core/offline/mobile_snapshot_store.dart';
import '../../../../core/offline/offline_queue_store.dart';
import '../../domain/models/tarea_formulario_detalle.dart';

/// Datasource offline para tareas y formularios.
class TareaFormularioOfflineDataSource {
  TareaFormularioOfflineDataSource({
    required MobileSnapshotStore snapshotStore,
    required OfflineQueueStore queueStore,
  })  : _snapshotStore = snapshotStore,
        _queueStore = queueStore;

  final MobileSnapshotStore _snapshotStore;
  final OfflineQueueStore _queueStore;
  final Uuid _uuid = const Uuid();

  /// Obtiene detalle de tarea desde cache local.
  TareaFormularioDetalle? obtenerDetalleOffline(String userId, String tareaId) {
    final Map<String, dynamic>? raw =
        _snapshotStore.getTareaDetalle(userId, tareaId);
    if (raw == null) return null;

    try {
      return _parseTareaDetalle(raw);
    } catch (e) {
      developer.log(
        '[OFFLINE][TAREA] Failed to parse cached tareaDetalle tareaId=$tareaId: $e',
        name: 'TareaFormularioOfflineDataSource',
      );
      return null;
    }
  }

  /// Guarda un borrador del formulario offline.
  Future<void> guardarBorradorOffline({
    required String userId,
    required String tareaId,
    required Map<String, dynamic> respuestas,
    String? observaciones,
  }) async {
    await _snapshotStore.saveFormDraft(userId, tareaId, <String, dynamic>{
      'respuestas': respuestas,
      'observaciones': observaciones,
      'timestamp': DateTime.now().toIso8601String(),
    });
    developer.log(
      '[OFFLINE][TAREA] Saved form draft tareaId=$tareaId',
      name: 'TareaFormularioOfflineDataSource',
    );
  }

  /// Obtiene el borrador guardado para una tarea.
  Map<String, dynamic>? obtenerBorradorOffline(String userId, String tareaId) {
    return _snapshotStore.getFormDraft(userId, tareaId);
  }

  /// Completa una tarea offline — guarda respuestas y las encola.
  Future<void> completarTareaOffline({
    required String userId,
    required String tareaId,
    required String? instanciaId,
    required Map<String, dynamic> formularioRespuesta,
    String? observaciones,
    String? localInstanciaId,
  }) async {
    final DateTime now = DateTime.now();

    // 1. Actualizar estado de la tarea en cache
    final Map<String, dynamic>? tareaCache =
        _snapshotStore.getTareaDetalle(userId, tareaId);
    if (tareaCache != null) {
      final Map<String, dynamic> updated =
          Map<String, dynamic>.from(tareaCache);
      updated['estadoTarea'] = 'PENDIENTE_SINCRONIZACION';
      updated['formularioRespuesta'] = formularioRespuesta;
      updated['observaciones'] = observaciones;
      updated['fechaCompletadoOffline'] = now.toIso8601String();
      await _snapshotStore.saveTareaDetalle(userId, tareaId, updated);
    }

    // 2. Limpiar borrador
    await _snapshotStore.clearFormDraft(userId, tareaId);

    // 3. Determinar endpoint: si tiene instanciaId real, usar endpoint normal
    final String resolvedInstanciaId = instanciaId ?? localInstanciaId ?? '';
    final String endpoint = NetworkConstants.tareaCompletarPath(tareaId);

    // 4. Encolar operación
    final OfflineQueueItem queueItem = OfflineQueueItem(
      id: _uuid.v4(),
      method: 'POST',
      endpoint: endpoint,
      entityType: OfflineEntityType.tareaCompletar,
      userId: userId,
      localInstanciaId: localInstanciaId,
      body: <String, dynamic>{
        'formularioRespuesta': formularioRespuesta,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      },
      headers: <String, String>{'X-User-Id': userId},
      createdAt: now,
    );

    await _queueStore.enqueue(queueItem);

    developer.log(
      '[OFFLINE][TAREA] Completed task offline tareaId=$tareaId instanciaId=$resolvedInstanciaId queueId=${queueItem.id}',
      name: 'TareaFormularioOfflineDataSource',
    );
  }

  /// Serializa datos de tarea desde el formato raw del cache al modelo de dominio.
  TareaFormularioDetalle _parseTareaDetalle(Map<String, dynamic> raw) {
    final dynamic camposRaw = raw['formularioDefinicion'] ?? raw['campos'] ?? <dynamic>[];
    final List<CampoFormularioDetalle> campos = <CampoFormularioDetalle>[];

    if (camposRaw is List) {
      for (final dynamic campo in camposRaw) {
        if (campo is Map) {
          campos.add(CampoFormularioDetalle(
            clave: campo['clave']?.toString() ?? campo['key']?.toString() ?? '',
            tipo: campo['tipo']?.toString() ?? campo['type']?.toString() ?? 'TEXTO',
            etiqueta: campo['etiqueta']?.toString() ?? campo['label']?.toString(),
            requerido: campo['requerido'] as bool? ?? campo['required'] as bool? ?? false,
            placeholder: campo['placeholder']?.toString(),
            ayuda: campo['ayuda']?.toString() ?? campo['help']?.toString(),
            opciones: _parseOpciones(campo['opciones'] ?? campo['options']),
          ));
        }
      }
    }

    final dynamic respRaw = raw['formularioRespuesta'] ?? raw['respuestas'] ?? <String, dynamic>{};
    final Map<String, dynamic> respuestas = respRaw is Map<String, dynamic>
        ? respRaw
        : <String, dynamic>{};

    return TareaFormularioDetalle(
      id: raw['id']?.toString() ?? '',
      estadoTarea: raw['estadoTarea']?.toString() ?? 'PENDIENTE',
      nombreActividad: raw['nombreActividad']?.toString() ?? raw['nombre']?.toString() ?? '',
      responsableTipo: raw['responsableTipo']?.toString() ?? '',
      responsableId: raw['responsableId']?.toString() ?? '',
      formularioDefinicion: campos,
      formularioRespuesta: respuestas,
      observaciones: raw['observaciones']?.toString() ?? '',
    );
  }

  List<String>? _parseOpciones(dynamic value) {
    if (value is List) {
      return value.map((dynamic e) => e.toString()).toList();
    }
    return null;
  }
}
