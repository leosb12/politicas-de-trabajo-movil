import '../../domain/models/mis_tramite_item.dart';
import '../../domain/repositories/mis_tramites_repository.dart';
import '../datasources/mis_tramites_mock_datasource.dart';

class MisTramitesRepositoryMock implements MisTramitesRepository {
  MisTramitesRepositoryMock(this._dataSource);

  final MisTramitesDataSource _dataSource;

  @override
  Future<List<MisTramiteItem>> obtenerMisTramites({required String usuarioId}) {
    return _dataSource.obtenerMisTramites(usuarioId: usuarioId);
  }
}