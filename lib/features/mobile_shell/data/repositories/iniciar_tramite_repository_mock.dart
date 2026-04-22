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
  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
  }) {
    return _dataSource.iniciarTramite(
      actorUserId: actorUserId,
      tramiteId: tramiteId,
    );
  }
}