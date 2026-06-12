import 'dart:developer' as developer;

import '../../../../core/offline/health_check_service.dart';
import '../../../../core/offline/mobile_snapshot_store.dart';
import '../../../../core/offline/offline_queue_store.dart';
import '../../domain/models/tramite_disponible_item.dart';
import '../../domain/repositories/iniciar_tramite_repository.dart';
import '../datasources/iniciar_tramite_mock_datasource.dart';
import '../datasources/iniciar_tramite_offline_datasource.dart';
import '../datasources/offline_tramite_classifier.dart';

/// Repositorio offline-first para iniciar trámites.
/// Si el backend está disponible → usa datasource remoto.
/// Si no → usa datasource offline (cache + cola).
class IniciarTramiteRepositoryImpl implements IniciarTramiteRepository {
  IniciarTramiteRepositoryImpl({
    required IniciarTramiteDataSource remoteDataSource,
    required MobileSnapshotStore snapshotStore,
    required OfflineQueueStore queueStore,
    required ConnectivityNotifier connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _offlineDataSource = IniciarTramiteOfflineDataSource(
          snapshotStore: snapshotStore,
          queueStore: queueStore,
        ),
        _snapshotStore = snapshotStore,
        _connectivity = connectivity;

  final IniciarTramiteDataSource _remoteDataSource;
  final IniciarTramiteOfflineDataSource _offlineDataSource;
  final MobileSnapshotStore _snapshotStore;
  final ConnectivityNotifier _connectivity;

  @override
  Future<List<TramiteDisponibleItem>> obtenerTramitesActivos({
    required String actorUserId,
  }) async {
    if (!_connectivity.isOnline) {
      developer.log(
        '[TRAMITES][REPO] Offline — reading from cache userId=$actorUserId',
        name: 'IniciarTramiteRepositoryImpl',
      );
      return _offlineDataSource.obtenerTramitesDisponiblesOffline(actorUserId);
    }

    try {
      final List<TramiteDisponibleItem> result =
          await _remoteDataSource.obtenerTramitesActivos(
        actorUserId: actorUserId,
      );

      // Actualizar cache en background
      await _snapshotStore.saveTramitesDisponibles(
        actorUserId,
        result.map(_tramiteToJson).toList(),
      );

      return result;
    } catch (e) {
      developer.log(
        '[TRAMITES][REPO] Remote failed, falling back to cache: $e',
        name: 'IniciarTramiteRepositoryImpl',
      );
      // Fallback a cache si la red falla inesperadamente
      return _offlineDataSource.obtenerTramitesDisponiblesOffline(actorUserId);
    }
  }

  @override
  Future<ClasificacionSolicitudResult> clasificarSolicitud({
    required String actorUserId,
    required String texto,
    bool usarDeepSeek = false,
    String? nombreDocumento,
    bool usarSoloRequisitosIniciales = false,
  }) async {
    final bool isOffline = !_connectivity.isOnline;
    if (isOffline) {
      final List<TramiteDisponibleItem> disponiblesOffline =
          _offlineDataSource.obtenerTramitesDisponiblesOffline(actorUserId);
      final List<dynamic>? catalogoDinamico =
          _snapshotStore.getCatalogoPoliticas(actorUserId);
      return OfflineTramiteClassifier.clasificar(
        texto: texto,
        nombreDocumento: nombreDocumento,
        politicasEnCache: disponiblesOffline,
        catalogoDinamico: catalogoDinamico,
        usarSoloRequisitosIniciales: usarSoloRequisitosIniciales,
      );
    }

    return _remoteDataSource.clasificarSolicitud(
      actorUserId: actorUserId,
      texto: texto,
      usarDeepSeek: usarDeepSeek,
      nombreDocumento: nombreDocumento,
      isOffline: isOffline,
      usarSoloRequisitosIniciales: usarSoloRequisitosIniciales,
    );
  }

  @override
  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  }) async {
    if (!_connectivity.isOnline) {
      // Buscar nombre del trámite en cache
      final List<TramiteDisponibleItem> disponibles =
          _offlineDataSource.obtenerTramitesDisponiblesOffline(actorUserId);
      final TramiteDisponibleItem? tramite = disponibles
          .where((TramiteDisponibleItem t) => t.id == tramiteId)
          .firstOrNull;

      if (tramite?.requierePago == true) {
        throw Exception(
          'Este trámite requiere conexión para procesar el pago.',
        );
      }

      await _offlineDataSource.iniciarTramiteOffline(
        actorUserId: actorUserId,
        tramiteId: tramiteId,
        tramiteNombre: tramite?.nombre ?? 'Trámite offline',
        respuestasRequisitosIniciales: respuestasRequisitosIniciales,
      );
      return;
    }

    await _remoteDataSource.iniciarTramite(
      actorUserId: actorUserId,
      tramiteId: tramiteId,
      respuestasRequisitosIniciales: respuestasRequisitosIniciales,
    );
  }

  Map<String, dynamic> _tramiteToJson(TramiteDisponibleItem t) =>
      <String, dynamic>{
        'id': t.id,
        'nombre': t.nombre,
        'descripcion': t.descripcion,
        'requierePago': t.requierePago,
        'tieneRequisitosIniciales': t.tieneRequisitosIniciales,
        'montoPago': t.montoPago,
        'monedaPago': t.monedaPago,
        'descripcionPago': t.descripcionPago,
      };
}
