import '../../domain/models/mis_tramite_item.dart';
import '../../domain/models/tramite_seguimiento.dart';
import '../../domain/repositories/mis_tramites_repository.dart';
import '../datasources/mis_tramites_mock_datasource.dart';

class MisTramitesRepositoryMock implements MisTramitesRepository {
  MisTramitesRepositoryMock(this._dataSource);

  final MisTramitesDataSource _dataSource;

  @override
  Future<List<MisTramiteItem>> obtenerMisTramites({required String usuarioId}) {
    return _dataSource.obtenerMisTramites(usuarioId: usuarioId);
  }

  @override
  Future<TramiteSeguimiento> obtenerSeguimiento({
    required String usuarioId,
    required String instanciaId,
  }) {
    return _dataSource.obtenerSeguimiento(
      usuarioId: usuarioId,
      instanciaId: instanciaId,
    );
  }
}
