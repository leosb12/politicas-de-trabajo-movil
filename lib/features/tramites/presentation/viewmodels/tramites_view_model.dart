import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/tramite_disponible.dart';
import '../../domain/usecases/iniciar_tramite_usecase.dart';
import '../../domain/usecases/obtener_tramites_disponibles_usecase.dart';
import 'tramites_state.dart';

class TramitesViewModel extends StateNotifier<TramitesState> {
  TramitesViewModel({
    required ObtenerTramitesDisponiblesUseCase
    obtenerTramitesDisponiblesUseCase,
    required IniciarTramiteUseCase iniciarTramiteUseCase,
  }) : _obtenerTramitesDisponiblesUseCase = obtenerTramitesDisponiblesUseCase,
       _iniciarTramiteUseCase = iniciarTramiteUseCase,
       super(TramitesState.initial());

  final ObtenerTramitesDisponiblesUseCase _obtenerTramitesDisponiblesUseCase;
  final IniciarTramiteUseCase _iniciarTramiteUseCase;

  Future<void> cargarTramites({required String actorUserId}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final tramites = await _obtenerTramitesDisponiblesUseCase(
        actorUserId: actorUserId,
      );

      state = state.copyWith(
        isLoading: false,
        tramites: tramites,
        clearError: true,
      );
    } on ApiFailure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar los tramites disponibles.',
      );
    }
  }

  Future<void> iniciarTramite({
    required String actorUserId,
    required TramiteDisponible tramite,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  }) async {
    state = state.copyWith(
      startingTramiteId: tramite.id,
      clearError: true,
      clearSuccess: true,
      clearUltimaInstanciaIniciada: true,
    );

    try {
      final instancia = await _iniciarTramiteUseCase(
        actorUserId: actorUserId,
        politicaId: tramite.id,
        respuestasRequisitosIniciales: respuestasRequisitosIniciales,
      );

      final String codigoVisible = instancia.codigoTramite.isNotEmpty
          ? instancia.codigoTramite
          : instancia.id;

      state = state.copyWith(
        clearStartingTramiteId: true,
        successMessage: 'Tramite iniciado correctamente: $codigoVisible',
        ultimaInstanciaIniciada: instancia,
        clearError: true,
      );
    } on ApiFailure catch (failure) {
      state = state.copyWith(
        clearStartingTramiteId: true,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = state.copyWith(
        clearStartingTramiteId: true,
        errorMessage: 'No se pudo iniciar el tramite.',
      );
    }
  }

  void clearFeedback() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
