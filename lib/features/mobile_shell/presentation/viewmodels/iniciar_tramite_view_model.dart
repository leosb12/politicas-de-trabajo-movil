import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../domain/models/tramite_disponible_item.dart';
import '../../domain/repositories/iniciar_tramite_repository.dart';
import 'iniciar_tramite_state.dart';

class IniciarTramiteViewModel extends StateNotifier<IniciarTramiteState> {
  IniciarTramiteViewModel({required IniciarTramiteRepository repository})
    : _repository = repository,
      super(IniciarTramiteState.initial());

  final IniciarTramiteRepository _repository;

  Future<void> cargarTramites({required String actorUserId}) async {
    state = state.copyWith(
      isLoading: true,
      lastLoadedUserId: actorUserId,
      clearError: true,
    );

    try {
      final List<TramiteDisponibleItem> tramites =
          await _repository.obtenerTramitesActivos(actorUserId: actorUserId);

      state = state.copyWith(
        isLoading: false,
        tramites: tramites,
        iniciandoTramiteIds: <String>{},
        lastLoadedUserId: actorUserId,
        clearError: true,
      );
    } on ApiFailure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        tramites: <TramiteDisponibleItem>[],
        lastLoadedUserId: actorUserId,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        tramites: <TramiteDisponibleItem>[],
        lastLoadedUserId: actorUserId,
        errorMessage: 'No se pudo cargar la lista de trámites activos.',
      );
    }
  }

  Future<String?> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
  }) async {
    if (state.isIniciando(tramiteId)) {
      return null;
    }

    final Set<String> iniciando = <String>{
      ...state.iniciandoTramiteIds,
      tramiteId,
    };
    state = state.copyWith(iniciandoTramiteIds: iniciando);

    try {
      await _repository.iniciarTramite(
        actorUserId: actorUserId,
        tramiteId: tramiteId,
      );

      final List<TramiteDisponibleItem> actualizados = state.tramites
          .map(
            (TramiteDisponibleItem item) => item.id == tramiteId
                ? item.copyWith(iniciado: true)
                : item,
          )
          .toList();

      iniciando.remove(tramiteId);
      state = state.copyWith(
        tramites: actualizados,
        iniciandoTramiteIds: iniciando,
      );
      return null;
    } on ApiFailure catch (failure) {
      iniciando.remove(tramiteId);
      state = state.copyWith(iniciandoTramiteIds: iniciando);
      return failure.message;
    } catch (_) {
      iniciando.remove(tramiteId);
      state = state.copyWith(iniciandoTramiteIds: iniciando);
      return 'No se pudo iniciar el trámite. Intenta nuevamente.';
    }
  }
}