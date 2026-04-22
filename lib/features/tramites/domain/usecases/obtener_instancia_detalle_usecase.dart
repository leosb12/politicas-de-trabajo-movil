import '../entities/instancia_iniciada.dart';
import '../repositories/tramites_repository.dart';

class ObtenerInstanciaDetalleUseCase {
  ObtenerInstanciaDetalleUseCase(this._tramitesRepository);

  final TramitesRepository _tramitesRepository;

  Future<InstanciaIniciada> call({
    required String actorUserId,
    required String instanciaId,
  }) {
    return _tramitesRepository.obtenerInstanciaDetalle(
      actorUserId: actorUserId,
      instanciaId: instanciaId,
    );
  }
}
