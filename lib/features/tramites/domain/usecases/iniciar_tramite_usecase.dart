import '../entities/instancia_iniciada.dart';
import '../repositories/tramites_repository.dart';

class IniciarTramiteUseCase {
  IniciarTramiteUseCase(this._repository);

  final TramitesRepository _repository;

  Future<InstanciaIniciada> call({
    required String actorUserId,
    required String politicaId,
  }) {
    return _repository.iniciarTramite(
      actorUserId: actorUserId,
      politicaId: politicaId,
    );
  }
}
