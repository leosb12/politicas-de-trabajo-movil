import '../../domain/entities/instancia_iniciada.dart';
import '../../domain/entities/tramite_disponible.dart';
import '../../domain/repositories/tramites_repository.dart';
import '../datasource/tramites_remote_datasource.dart';

class TramitesRepositoryImpl implements TramitesRepository {
  TramitesRepositoryImpl({required TramitesRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TramitesRemoteDataSource _remoteDataSource;

  @override
  Future<List<TramiteDisponible>> obtenerDisponibles({
    required String actorUserId,
  }) async {
    final models = await _remoteDataSource.obtenerDisponibles(
      actorUserId: actorUserId,
    );

    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<InstanciaIniciada> iniciarTramite({
    required String actorUserId,
    required String politicaId,
  }) async {
    final model = await _remoteDataSource.iniciarTramite(
      actorUserId: actorUserId,
      politicaId: politicaId,
    );

    return model.toEntity();
  }
}
