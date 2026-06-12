import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

import '../../../../core/network/network_constants.dart';
import '../../../../core/offline/mobile_snapshot_store.dart';
import '../../../../core/offline/offline_queue_store.dart';
import '../../domain/models/tramite_disponible_item.dart';

/// Datasource offline para iniciar y consultar trámites sin internet.
class IniciarTramiteOfflineDataSource {
  IniciarTramiteOfflineDataSource({
    required MobileSnapshotStore snapshotStore,
    required OfflineQueueStore queueStore,
  })  : _snapshotStore = snapshotStore,
        _queueStore = queueStore;

  final MobileSnapshotStore _snapshotStore;
  final OfflineQueueStore _queueStore;
  final Uuid _uuid = const Uuid();

  /// Obtiene trámites disponibles desde cache local.
  List<TramiteDisponibleItem> obtenerTramitesDisponiblesOffline(
    String userId,
  ) {
    final List<dynamic>? raw =
        _snapshotStore.getTramitesDisponibles(userId);
    if (raw == null) return <TramiteDisponibleItem>[];

    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(_parseTramiteDisponible)
        .whereType<TramiteDisponibleItem>()
        .toList();
  }

  /// Inicia un trámite offline: crea instancia local y la encola.
  Future<String> iniciarTramiteOffline({
    required String actorUserId,
    required String tramiteId,
    required String tramiteNombre,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  }) async {
    final String localId = 'local_${_uuid.v4()}';
    final String codigoTemporal = 'PENDIENTE-SYNC';
    final DateTime now = DateTime.now();

    // 1. Crear instancia local
    final Map<String, dynamic> instanciaLocal = <String, dynamic>{
      'id': localId,
      'localId': localId,
      'usuarioId': actorUserId,
      'codigoTramite': codigoTemporal,
      'nombre': tramiteNombre,
      'nombrePolitica': tramiteNombre,
      'politicaId': tramiteId,
      'estado': 'PENDIENTE_SINCRONIZACION',
      'estadoLocal': 'PENDIENTE_SINCRONIZACION',
      'estadoVisual': 'PENDIENTE DE SINCRONIZACIÓN',
      'estadoInstancia': 'PENDIENTE_SINCRONIZACION',
      'progreso': 0.0,
      'porcentaje': 0,
      'porcentajeLocal': 0,
      'fechaCreacion': now.toIso8601String(),
      'fechaCreacionLocal': now.toIso8601String(),
      'fechaCreacionOffline': now.toIso8601String(),
      'esOffline': true,
      'respuestasRequisitosIniciales': respuestasRequisitosIniciales,
      'datosIniciales': respuestasRequisitosIniciales,
      'requisitosCompletados': respuestasRequisitosIniciales,
      'archivosPendientes': <String, dynamic>{},
    };

    // 2. Guardar en snapshot (aparece en Mis Trámites)
    await _snapshotStore.addTramiteOffline(actorUserId, instanciaLocal);

    // 3. Crear seguimiento estimado
    await _snapshotStore.saveSeguimiento(
      actorUserId,
      localId,
      <String, dynamic>{
        'instanciaId': localId,
        'politicaId': tramiteId,
        'politicaNombre': tramiteNombre,
        'codigoTramite': codigoTemporal,
        'estadoInstancia': 'PENDIENTE_SINCRONIZACION',
        'laneOrientation': 'horizontal',
        'nodos': <dynamic>[],
        'conexiones': <dynamic>[],
        'tareas': <dynamic>[],
        'documentos': <dynamic>[],
        'departamentosActuales': <dynamic>[],
        'nodosActualesIds': <dynamic>[],
        'esOffline': true,
      },
    );

    // 4. Encolar operación
    final OfflineQueueItem queueItem = OfflineQueueItem(
      id: _uuid.v4(),
      method: 'POST',
      endpoint: NetworkConstants.instanciasPath,
      entityType: OfflineEntityType.instanciaTramite,
      userId: actorUserId,
      localId: localId,
      body: <String, dynamic>{
        'politicaId': tramiteId,
        if (respuestasRequisitosIniciales != null)
          'respuestasRequisitosIniciales': respuestasRequisitosIniciales,
      },
      headers: <String, String>{'X-User-Id': actorUserId},
      createdAt: now,
    );

    await _queueStore.enqueue(queueItem);

    developer.log(
      '[OFFLINE][TRAMITE] Created offline instancia localId=$localId politicaId=$tramiteId',
      name: 'IniciarTramiteOfflineDataSource',
    );

    return localId;
  }

  TramiteDisponibleItem? _parseTramiteDisponible(Map<dynamic, dynamic> item) {
    try {
      final String id = item['id']?.toString().trim() ?? '';
      if (id.isEmpty) return null;

      return TramiteDisponibleItem(
        id: id,
        nombre: item['nombre']?.toString().trim() ?? '',
        descripcion: item['descripcion']?.toString().trim() ?? '',
        categoria: 'Tramite',
        requierePago: item['requierePago'] as bool? ?? false,
        tieneRequisitosIniciales:
            item['tieneRequisitosIniciales'] as bool? ?? false,
        montoPago: _readDouble(item['montoPago']),
        monedaPago: item['monedaPago']?.toString(),
        descripcionPago: item['descripcionPago']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
