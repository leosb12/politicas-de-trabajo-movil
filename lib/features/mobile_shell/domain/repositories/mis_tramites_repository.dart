import '../models/mis_tramite_item.dart';
import '../models/tramite_seguimiento.dart';
import '../../data/datasources/mis_tramites_mock_datasource.dart';

abstract class MisTramitesRepository {
  Future<List<MisTramiteItem>> obtenerMisTramites({required String usuarioId});

  Future<TramiteSeguimiento> obtenerSeguimiento({
    required String usuarioId,
    required String instanciaId,
  });

  Future<DocumentoArchivoBinario> verDocumento({
    required String usuarioId,
    required String archivoId,
  });

  Future<DocumentoArchivoBinario> descargarDocumento({
    required String usuarioId,
    required String archivoId,
  });

  Future<void> editarDocumento({
    required String usuarioId,
    required String archivoId,
    required String nombreOriginal,
    required String descripcion,
  });

  Future<void> reemplazarDocumento({
    required String usuarioId,
    required String archivoId,
    required String nombreArchivo,
    required List<int> bytes,
  });

  Future<void> eliminarDocumento({
    required String usuarioId,
    required String archivoId,
  });
}
