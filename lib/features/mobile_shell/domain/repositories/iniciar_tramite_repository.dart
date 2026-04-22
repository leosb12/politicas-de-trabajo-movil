import '../models/tramite_disponible_item.dart';

abstract class IniciarTramiteRepository {
  Future<List<TramiteDisponibleItem>> obtenerTramitesActivos({
    required String actorUserId,
  });

  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
  });
}