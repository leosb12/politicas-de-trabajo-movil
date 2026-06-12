import 'dart:developer' as developer;

import '../../../../core/offline/health_check_service.dart';
import '../../../../core/offline/mobile_snapshot_store.dart';
import '../../domain/models/mis_tramite_item.dart';
import '../../domain/models/tramite_seguimiento.dart';
import '../../domain/repositories/mis_tramites_repository.dart';
import '../datasources/mis_tramites_mock_datasource.dart';
import '../models/tramite_seguimiento_model.dart';

/// Repositorio offline-first para mis trámites y seguimientos.
class MisTramitesRepositoryImpl implements MisTramitesRepository {
  MisTramitesRepositoryImpl({
    required MisTramitesDataSource remoteDataSource,
    required MobileSnapshotStore snapshotStore,
    required ConnectivityNotifier connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _snapshotStore = snapshotStore,
        _connectivity = connectivity;

  final MisTramitesDataSource _remoteDataSource;
  final MobileSnapshotStore _snapshotStore;
  final ConnectivityNotifier _connectivity;

  @override
  Future<List<MisTramiteItem>> obtenerMisTramites({
    required String usuarioId,
  }) async {
    if (!_connectivity.isOnline) {
      developer.log(
        '[MIS_TRAMITES][REPO] Offline — reading from cache',
        name: 'MisTramitesRepositoryImpl',
      );
      return _getMisTramitesFromCache(usuarioId);
    }

    try {
      final List<MisTramiteItem> items =
          await _remoteDataSource.obtenerMisTramites(usuarioId: usuarioId);

      // Actualizar cache con datos del servidor
      final List<Map<String, dynamic>> serialized = items
          .map((MisTramiteItem i) => <String, dynamic>{
                'id': i.id,
                'usuarioId': i.usuarioId,
                'codigoTramite': i.codigoTramite,
                'nombre': i.nombre,
                'estadoInstancia': i.estado,
                'porcentaje': (i.progreso * 100).round(),
                'fechaCreacion': i.fechaCreacion.toIso8601String(),
              })
          .toList();

      // Combinar con tramites offline pendientes
      final List<dynamic>? cached = _snapshotStore.getMisTramites(usuarioId);
      final List<Map<String, dynamic>> offlinePendientes =
          _getOfflinePendientes(cached ?? <dynamic>[]);

      await _snapshotStore.saveMisTramites(
        usuarioId,
        <dynamic>[...offlinePendientes, ...serialized],
      );

      return <MisTramiteItem>[
        ..._offlinePendientesToDomain(offlinePendientes, usuarioId),
        ...items,
      ];
    } catch (e) {
      developer.log(
        '[MIS_TRAMITES][REPO] Remote failed, using cache: $e',
        name: 'MisTramitesRepositoryImpl',
      );
      return _getMisTramitesFromCache(usuarioId);
    }
  }

  @override
  Future<TramiteSeguimiento> obtenerSeguimiento({
    required String usuarioId,
    required String instanciaId,
  }) async {
    if (!_connectivity.isOnline) {
      developer.log(
        '[MIS_TRAMITES][REPO] Offline seguimiento — reading from cache instanciaId=$instanciaId',
        name: 'MisTramitesRepositoryImpl',
      );
      return _getSeguimientoFromCache(usuarioId, instanciaId);
    }

    try {
      final TramiteSeguimiento seg =
          await _remoteDataSource.obtenerSeguimiento(
        usuarioId: usuarioId,
        instanciaId: instanciaId,
      );

      // Serializar y cachear
      final Map<String, dynamic> serialized = _seguimientoToJson(seg);
      await _snapshotStore.saveSeguimiento(usuarioId, instanciaId, serialized);

      return seg;
    } catch (e) {
      developer.log(
        '[MIS_TRAMITES][REPO] Seguimiento remote failed, using cache: $e',
        name: 'MisTramitesRepositoryImpl',
      );
      return _getSeguimientoFromCache(usuarioId, instanciaId);
    }
  }

  // ── Métodos de la interfaz extendida (ver/descargar doc) ──────────────────

  @override
  Future<DocumentoArchivoBinario> verDocumento({
    required String usuarioId,
    required String archivoId,
  }) {
    return _remoteDataSource.verDocumento(
      usuarioId: usuarioId,
      archivoId: archivoId,
    );
  }

  @override
  Future<DocumentoArchivoBinario> descargarDocumento({
    required String usuarioId,
    required String archivoId,
  }) {
    return _remoteDataSource.descargarDocumento(
      usuarioId: usuarioId,
      archivoId: archivoId,
    );
  }

  @override
  Future<void> editarDocumento({
    required String usuarioId,
    required String archivoId,
    required String nombreOriginal,
    required String descripcion,
  }) {
    return _remoteDataSource.editarDocumento(
      usuarioId: usuarioId,
      archivoId: archivoId,
      nombreOriginal: nombreOriginal,
      descripcion: descripcion,
    );
  }

  @override
  Future<void> reemplazarDocumento({
    required String usuarioId,
    required String archivoId,
    required String nombreArchivo,
    required List<int> bytes,
  }) {
    return _remoteDataSource.reemplazarDocumento(
      usuarioId: usuarioId,
      archivoId: archivoId,
      nombreArchivo: nombreArchivo,
      bytes: bytes,
    );
  }

  @override
  Future<void> eliminarDocumento({
    required String usuarioId,
    required String archivoId,
  }) {
    return _remoteDataSource.eliminarDocumento(
      usuarioId: usuarioId,
      archivoId: archivoId,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<MisTramiteItem> _getMisTramitesFromCache(String usuarioId) {
    final List<dynamic>? cached = _snapshotStore.getMisTramites(usuarioId);
    if (cached == null || cached.isEmpty) return <MisTramiteItem>[];

    return cached
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> raw) => _misTramiteFromJson(raw, usuarioId))
        .whereType<MisTramiteItem>()
        .toList();
  }

  MisTramiteItem? _misTramiteFromJson(
    Map<dynamic, dynamic> raw,
    String usuarioId,
  ) {
    try {
      final String id = raw['id']?.toString() ?? '';
      if (id.isEmpty) return null;

      final String estadoRaw =
          (raw['estadoInstancia']?.toString() ?? raw['estado']?.toString() ?? '')
              .toUpperCase();

      return MisTramiteItem(
        id: id,
        usuarioId: raw['usuarioId']?.toString() ?? usuarioId,
        codigoTramite: raw['codigoTramite']?.toString() ?? '',
        nombre: raw['nombre']?.toString().isNotEmpty == true
            ? raw['nombre'].toString()
            : 'Trámite sin nombre',
        estado: _normalizarEstado(estadoRaw),
        progreso: _parsePorcentaje(raw['porcentaje']),
        fechaCreacion: _parseDate(raw['fechaCreacion']),
      );
    } catch (_) {
      return null;
    }
  }

  /// Devuelve los trámites offline pendientes de la lista cacheada.
  List<Map<String, dynamic>> _getOfflinePendientes(List<dynamic> cached) {
    return cached
        .whereType<Map<dynamic, dynamic>>()
        .where((Map<dynamic, dynamic> t) => t['esOffline'] == true)
        .map((Map<dynamic, dynamic> t) => t.map(
              (dynamic k, dynamic v) =>
                  MapEntry<String, dynamic>(k.toString(), v),
            ))
        .toList();
  }

  List<MisTramiteItem> _offlinePendientesToDomain(
    List<Map<String, dynamic>> pendientes,
    String usuarioId,
  ) {
    return pendientes
        .map((Map<String, dynamic> raw) =>
            _misTramiteFromJson(raw, usuarioId))
        .whereType<MisTramiteItem>()
        .toList();
  }

  TramiteSeguimiento _getSeguimientoFromCache(
      String userId, String instanciaId) {
    final Map<String, dynamic>? cached =
        _snapshotStore.getSeguimiento(userId, instanciaId);

    if (cached == null ||
        (cached['nodos'] is List && (cached['nodos'] as List).isEmpty)) {
      final List<dynamic>? cachedTramites = _snapshotStore.getMisTramites(userId);
      Map<String, dynamic>? localTramite;
      if (cachedTramites != null) {
        localTramite = cachedTramites
            .whereType<Map<dynamic, dynamic>>()
            .map((t) => Map<String, dynamic>.from(t))
            .where((t) => t['id']?.toString() == instanciaId)
            .firstOrNull;
      }

      if (localTramite != null) {
        final String politicaId = localTramite['politicaId']?.toString() ?? '';
        final List<dynamic>? catalog = _snapshotStore.getCatalogoPoliticas(userId);
        if (catalog != null) {
          final Map<String, dynamic>? policy = catalog
              .whereType<Map<dynamic, dynamic>>()
              .map((p) => Map<String, dynamic>.from(p))
              .where((p) => p['id']?.toString() == politicaId)
              .firstOrNull;

          if (policy != null) {
            developer.log(
              '[MIS_TRAMITES][REPO] Offline seguimiento — generating from catalog policy $politicaId',
              name: 'MisTramitesRepositoryImpl',
            );
            return TramiteSeguimiento(
              instanciaId: instanciaId,
              politicaId: policy['id']?.toString() ?? '',
              politicaNombre: policy['nombre']?.toString() ?? localTramite['nombre']?.toString() ?? 'Trámite offline',
              codigoTramite: localTramite['codigoTramite']?.toString() ?? 'PENDIENTE-SYNC',
              estadoInstancia: localTramite['estado']?.toString() ?? localTramite['estadoInstancia']?.toString() ?? 'PENDIENTE_SINCRONIZACION',
              laneOrientation: policy['laneOrientation']?.toString() ?? 'horizontal',
              laneWidth: policy['laneWidth'] != null ? (policy['laneWidth'] as num).toDouble() : null,
              laneHeight: policy['laneHeight'] != null ? (policy['laneHeight'] as num).toDouble() : null,
              nodos: policy['nodos'] != null
                  ? (policy['nodos'] as List)
                      .whereType<Map<dynamic, dynamic>>()
                      .map((n) {
                        final Map<String, dynamic> map = Map<String, dynamic>.from(n);
                        return NodoSeguimiento(
                          id: map['id']?.toString() ?? '',
                          tipo: map['tipo']?.toString() ?? '',
                          nombre: map['nombre']?.toString() ?? '',
                          departamentoId: map['departamentoId']?.toString() ?? '',
                          departamentoNombre: map['departamentoNombre']?.toString() ?? '',
                          responsableTipo: map['responsableTipo']?.toString() ?? '',
                          responsableId: map['responsableId']?.toString() ?? '',
                          responsableNombre: map['responsableNombre']?.toString() ?? '',
                          posX: map['posX'] != null ? (map['posX'] as num).toDouble() : null,
                          posY: map['posY'] != null ? (map['posY'] as num).toDouble() : null,
                          estadoSeguimiento: 'PENDIENTE',
                          tareaActualId: '',
                          estadoTareaActual: '',
                          asignadoA: '',
                          asignadoANombre: '',
                        );
                      })
                      .toList()
                  : const <NodoSeguimiento>[],
              conexiones: policy['conexiones'] != null
                  ? (policy['conexiones'] as List)
                      .whereType<Map<dynamic, dynamic>>()
                      .map((c) {
                        final Map<String, dynamic> map = Map<String, dynamic>.from(c);
                        return ConexionSeguimiento(
                          origen: map['origen']?.toString() ?? map['source']?.toString() ?? '',
                          destino: map['destino']?.toString() ?? map['target']?.toString() ?? '',
                          puertoOrigen: map['puertoOrigen']?.toString() ?? '',
                          puertoDestino: map['puertoDestino']?.toString() ?? '',
                        );
                      })
                      .toList()
                  : const <ConexionSeguimiento>[],
              tareas: const <TareaSeguimiento>[],
              documentos: const <DocumentoSeguimiento>[],
              departamentosActuales: const <DepartamentoActualSeguimiento>[],
              nodosActualesIds: const <String>[],
            );
          }
        }
      }
    }

    if (cached == null) {
      // Si es un trámite offline, devolver seguimiento vacío con estado estimado
      return TramiteSeguimiento(
        instanciaId: instanciaId,
        politicaId: '',
        politicaNombre: '',
        codigoTramite: 'PENDIENTE-SYNC',
        estadoInstancia: 'PENDIENTE_SINCRONIZACION',
        laneOrientation: 'horizontal',
        laneWidth: null,
        laneHeight: null,
        nodos: const <NodoSeguimiento>[],
        conexiones: const <ConexionSeguimiento>[],
        tareas: const <TareaSeguimiento>[],
        documentos: const <DocumentoSeguimiento>[],
        departamentosActuales: const <DepartamentoActualSeguimiento>[],
        nodosActualesIds: const <String>[],
      );
    }

    return TramiteSeguimientoModel.fromJson(
      cached.map((String k, dynamic v) => MapEntry<String, dynamic>(k, v)),
    ).toDomain();
  }

  Map<String, dynamic> _seguimientoToJson(TramiteSeguimiento seg) {
    return <String, dynamic>{
      'instanciaId': seg.instanciaId,
      'politicaId': seg.politicaId,
      'politicaNombre': seg.politicaNombre,
      'codigoTramite': seg.codigoTramite,
      'estadoInstancia': seg.estadoInstancia,
      'laneOrientation': seg.laneOrientation,
      'laneWidth': seg.laneWidth,
      'laneHeight': seg.laneHeight,
      'nodos': seg.nodos
          .map((NodoSeguimiento n) => <String, dynamic>{
                'id': n.id,
                'tipo': n.tipo,
                'nombre': n.nombre,
                'departamentoId': n.departamentoId,
                'departamentoNombre': n.departamentoNombre,
                'responsableTipo': n.responsableTipo,
                'responsableId': n.responsableId,
                'responsableNombre': n.responsableNombre,
                'posX': n.posX,
                'posY': n.posY,
                'estadoSeguimiento': n.estadoSeguimiento,
                'tareaActualId': n.tareaActualId,
                'estadoTareaActual': n.estadoTareaActual,
                'asignadoA': n.asignadoA,
                'asignadoANombre': n.asignadoANombre,
              })
          .toList(),
      'conexiones': seg.conexiones
          .map((ConexionSeguimiento c) => <String, dynamic>{
                'origen': c.origen,
                'destino': c.destino,
                'puertoOrigen': c.puertoOrigen,
                'puertoDestino': c.puertoDestino,
              })
          .toList(),
      'tareas': seg.tareas
          .map((TareaSeguimiento t) => <String, dynamic>{
                'id': t.id,
                'nodoId': t.nodoId,
                'nombre': t.nombre,
                'responsableTipo': t.responsableTipo,
                'responsableId': t.responsableId,
                'responsableNombre': t.responsableNombre,
                'estado': t.estado,
                'asignadoA': t.asignadoA,
                'asignadoANombre': t.asignadoANombre,
              })
          .toList(),
      'departamentosActuales': seg.departamentosActuales
          .map((DepartamentoActualSeguimiento d) => <String, dynamic>{
                'departamentoId': d.departamentoId,
                'departamentoNombre': d.departamentoNombre,
                'nodoId': d.nodoId,
                'nodoNombre': d.nodoNombre,
                'tareaId': d.tareaId,
                'estadoTarea': d.estadoTarea,
                'responsableTipo': d.responsableTipo,
                'responsableNombre': d.responsableNombre,
                'asignadoANombre': d.asignadoANombre,
              })
          .toList(),
      'nodosActualesIds': seg.nodosActualesIds,
    };
  }

  String _normalizarEstado(String estadoRaw) {
    switch (estadoRaw) {
      case 'EN_CURSO':
        return 'En curso';
      case 'FINALIZADA':
        return 'Finalizada';
      case 'PAUSADA':
        return 'Pausada';
      case 'CANCELADA':
        return 'Cancelada';
      case 'PENDIENTE_SINCRONIZACION':
        return 'Pendiente de sincronización';
      default:
        return estadoRaw.isEmpty ? 'Sin estado' : estadoRaw;
    }
  }

  double _parsePorcentaje(dynamic value) {
    if (value is num) return (value / 100).clamp(0, 1).toDouble();
    if (value is String) {
      final double? d = double.tryParse(value.replaceAll(',', '.'));
      if (d != null) return (d / 100).clamp(0, 1).toDouble();
    }
    return 0;
  }

  DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
