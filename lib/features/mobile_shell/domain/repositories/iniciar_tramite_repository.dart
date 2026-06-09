import '../models/tramite_disponible_item.dart';

abstract class IniciarTramiteRepository {
  Future<List<TramiteDisponibleItem>> obtenerTramitesActivos({
    required String actorUserId,
  });

  Future<ClasificacionSolicitudResult> clasificarSolicitud({
    required String actorUserId,
    required String texto,
    bool usarDeepSeek = false,
    String? nombreDocumento,
  });

  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  });
}
