import '../models/mis_tramite_item.dart';

abstract class MisTramitesRepository {
  Future<List<MisTramiteItem>> obtenerMisTramites({required String usuarioId});
}