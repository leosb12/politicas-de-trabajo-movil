import '../entities/instancia_iniciada.dart';
import '../repositories/tramites_repository.dart';

class ObtenerInstanciasUseCase {
  ObtenerInstanciasUseCase(this._tramitesRepository);

  final TramitesRepository _tramitesRepository;

  Future<List<InstanciaIniciada>> call({
    required String actorUserId,
    String? estado,
  }) {
    return _tramitesRepository.obtenerInstancias(
      actorUserId: actorUserId,
      estado: estado,
    );
  }
}
