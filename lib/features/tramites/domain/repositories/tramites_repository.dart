import '../../../mobile_shell/domain/models/tarea_formulario_detalle.dart';
import '../entities/instancia_iniciada.dart';
import '../entities/tramite_disponible.dart';

abstract class TramitesRepository {
  Future<List<TramiteDisponible>> obtenerDisponibles({
    required String actorUserId,
  });

  Future<List<InstanciaIniciada>> obtenerInstancias({
    required String actorUserId,
    String? estado,
  });

  Future<InstanciaIniciada> obtenerInstanciaDetalle({
    required String actorUserId,
    required String instanciaId,
  });

  Future<InstanciaIniciada> iniciarTramite({
    required String actorUserId,
    required String politicaId,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  });

  Future<List<CampoFormularioDetalle>> obtenerRequisitosIniciales({
    required String actorUserId,
    required String politicaId,
  });
}
