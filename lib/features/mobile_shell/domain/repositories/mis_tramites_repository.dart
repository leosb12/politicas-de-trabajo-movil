import '../models/mis_tramite_item.dart';
import '../models/tramite_seguimiento.dart';

abstract class MisTramitesRepository {
  Future<List<MisTramiteItem>> obtenerMisTramites({required String usuarioId});

  Future<TramiteSeguimiento> obtenerSeguimiento({
    required String usuarioId,
    required String instanciaId,
  });
}
