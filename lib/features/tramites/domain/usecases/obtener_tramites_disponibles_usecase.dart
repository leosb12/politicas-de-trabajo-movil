import '../entities/tramite_disponible.dart';
import '../repositories/tramites_repository.dart';

class ObtenerTramitesDisponiblesUseCase {
  ObtenerTramitesDisponiblesUseCase(this._repository);

  final TramitesRepository _repository;

  Future<List<TramiteDisponible>> call({required String actorUserId}) {
    return _repository.obtenerDisponibles(actorUserId: actorUserId);
  }
}
