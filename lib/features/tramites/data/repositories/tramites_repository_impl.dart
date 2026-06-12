import '../../../mobile_shell/domain/models/tarea_formulario_detalle.dart';
import '../../domain/entities/instancia_iniciada.dart';
import '../../domain/entities/tramite_disponible.dart';
import '../../domain/repositories/tramites_repository.dart';
import '../datasource/tramites_remote_datasource.dart';
import '../../../../core/offline/health_check_service.dart';
import '../../../../core/offline/mobile_snapshot_store.dart';
import '../../../mobile_shell/data/models/tarea_formulario_detalle_model.dart';

class TramitesRepositoryImpl implements TramitesRepository {
  TramitesRepositoryImpl({
    required TramitesRemoteDataSource remoteDataSource,
    required MobileSnapshotStore snapshotStore,
    required ConnectivityNotifier connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _snapshotStore = snapshotStore,
        _connectivity = connectivity;

  final TramitesRemoteDataSource _remoteDataSource;
  final MobileSnapshotStore _snapshotStore;
  final ConnectivityNotifier _connectivity;

  @override
  Future<List<TramiteDisponible>> obtenerDisponibles({
    required String actorUserId,
  }) async {
    final models = await _remoteDataSource.obtenerDisponibles(
      actorUserId: actorUserId,
    );

    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<List<InstanciaIniciada>> obtenerInstancias({
    required String actorUserId,
    String? estado,
  }) async {
    final models = await _remoteDataSource.obtenerInstancias(
      actorUserId: actorUserId,
      estado: estado,
    );

    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<InstanciaIniciada> obtenerInstanciaDetalle({
    required String actorUserId,
    required String instanciaId,
  }) async {
    throw UnimplementedError(
      'obtenerInstanciaDetalle aun no esta implementado en TramitesRepositoryImpl.',
    );
  }

  @override
  Future<InstanciaIniciada> iniciarTramite({
    required String actorUserId,
    required String politicaId,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  }) async {
    final model = await _remoteDataSource.iniciarTramite(
      actorUserId: actorUserId,
      politicaId: politicaId,
      respuestasRequisitosIniciales: respuestasRequisitosIniciales,
    );

    return model.toEntity();
  }

  @override
  Future<List<CampoFormularioDetalle>> obtenerRequisitosIniciales({
    required String actorUserId,
    required String politicaId,
  }) async {
    if (!_connectivity.isOnline) {
      final List<dynamic>? catalogo = _snapshotStore.getCatalogoPoliticas(actorUserId);
      if (catalogo != null) {
        final Map<String, dynamic>? politica = catalogo
            .whereType<Map<dynamic, dynamic>>()
            .map((p) => Map<String, dynamic>.from(p))
            .where((p) => p['id']?.toString() == politicaId)
            .firstOrNull;

        if (politica != null) {
          final dynamic reqs = politica['requisitosIniciales'];
          if (reqs is List) {
            final List<CampoFormularioDetalleModel> models = reqs
                .whereType<Map<dynamic, dynamic>>()
                .map((m) => CampoFormularioDetalleModel.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            return models.map((model) => model.toDomain()).toList(growable: false);
          }
        }
      }
      return <CampoFormularioDetalle>[];
    }

    final models = await _remoteDataSource.obtenerRequisitosIniciales(
      actorUserId: actorUserId,
      politicaId: politicaId,
    );

    return models.map((model) => model.toDomain()).toList(growable: false);
  }
}