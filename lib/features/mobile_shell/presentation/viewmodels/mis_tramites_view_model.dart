import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../domain/models/mis_tramite_item.dart';
import '../../domain/repositories/mis_tramites_repository.dart';
import 'mis_tramites_state.dart';

class MisTramitesViewModel extends StateNotifier<MisTramitesState> {
  MisTramitesViewModel({required MisTramitesRepository repository})
    : _repository = repository,
      super(MisTramitesState.initial());

  final MisTramitesRepository _repository;

  Future<void> cargarMisTramites({required String usuarioId}) async {
    state = state.copyWith(
      isLoading: true,
      lastLoadedUserId: usuarioId,
      clearError: true,
    );

    try {
      final List<MisTramiteItem> items = await _repository.obtenerMisTramites(
        usuarioId: usuarioId,
      );

      state = state.copyWith(isLoading: false, tramites: items, clearError: true);
    } on ApiFailure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        tramites: <MisTramiteItem>[],
        lastLoadedUserId: usuarioId,
        errorMessage: failure.message,
      );
      return;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        tramites: <MisTramiteItem>[],
        lastLoadedUserId: usuarioId,
        errorMessage: 'No se pudieron cargar tus trámites.',
      );
      return;
    }

    state = state.copyWith(lastLoadedUserId: usuarioId);
  }
}