import '../../../mobile_shell/domain/models/tarea_formulario_detalle.dart';
import '../repositories/tramites_repository.dart';

class ObtenerRequisitosInicialesUseCase {
  ObtenerRequisitosInicialesUseCase(this._repository);

  final TramitesRepository _repository;

  Future<List<CampoFormularioDetalle>> call({
    required String actorUserId,
    required String politicaId,
  }) {
    return _repository.obtenerRequisitosIniciales(
      actorUserId: actorUserId,
      politicaId: politicaId,
    );
  }
}
