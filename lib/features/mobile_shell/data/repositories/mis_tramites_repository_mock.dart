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

  @override
  Future<DocumentoArchivoBinario> verDocumento({
    required String usuarioId,
    required String archivoId,
  }) {
    return _dataSource.verDocumento(
      usuarioId: usuarioId,
      archivoId: archivoId,
    );
  }

  @override
  Future<DocumentoArchivoBinario> descargarDocumento({
    required String usuarioId,
    required String archivoId,
  }) {
    return _dataSource.descargarDocumento(
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
    return _dataSource.editarDocumento(
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
    return _dataSource.reemplazarDocumento(
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
    return _dataSource.eliminarDocumento(
      usuarioId: usuarioId,
      archivoId: archivoId,
    );
  }
}
