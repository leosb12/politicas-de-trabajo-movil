import '../../domain/models/tramite_disponible_item.dart';
import '../../domain/repositories/iniciar_tramite_repository.dart';
import '../datasources/iniciar_tramite_mock_datasource.dart';

class IniciarTramiteRepositoryMock implements IniciarTramiteRepository {
  IniciarTramiteRepositoryMock(this._dataSource);

  final IniciarTramiteDataSource _dataSource;

  @override
  Future<List<TramiteDisponibleItem>> obtenerTramitesActivos({
    required String actorUserId,
  }) {
    return _dataSource.obtenerTramitesActivos(actorUserId: actorUserId);
  }

  @override
  Future<ClasificacionSolicitudResult> clasificarSolicitud({
    required String actorUserId,
    required String texto,
    bool usarDeepSeek = false,
  }) {
    return _dataSource.clasificarSolicitud(
      actorUserId: actorUserId,
      texto: texto,
      usarDeepSeek: usarDeepSeek,
    );
  }

  @override
  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  }) {
    return _dataSource.iniciarTramite(
      actorUserId: actorUserId,
      tramiteId: tramiteId,
      respuestasRequisitosIniciales: respuestasRequisitosIniciales,
    );
  }
}
