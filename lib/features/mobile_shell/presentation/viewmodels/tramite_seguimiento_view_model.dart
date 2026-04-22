import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../domain/models/tramite_seguimiento.dart';
import '../../domain/repositories/mis_tramites_repository.dart';
import 'tramite_seguimiento_state.dart';

class TramiteSeguimientoArgs {
  const TramiteSeguimientoArgs({
    required this.usuarioId,
    required this.instanciaId,
  });

  final String usuarioId;
  final String instanciaId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TramiteSeguimientoArgs &&
            other.usuarioId == usuarioId &&
            other.instanciaId == instanciaId;
  }

  @override
  int get hashCode => Object.hash(usuarioId, instanciaId);
}

class TramiteSeguimientoViewModel
    extends StateNotifier<TramiteSeguimientoState> {
  TramiteSeguimientoViewModel({
    required MisTramitesRepository repository,
    required String usuarioId,
    required String instanciaId,
  }) : _repository = repository,
       _usuarioId = usuarioId,
       _instanciaId = instanciaId,
       super(TramiteSeguimientoState.initial());

  final MisTramitesRepository _repository;
  final String _usuarioId;
  final String _instanciaId;

  Future<void> cargarSeguimiento() async {
    final String usuarioId = _usuarioId.trim();
    final String instanciaId = _instanciaId.trim();

    if (usuarioId.isEmpty || instanciaId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo identificar el tramite a consultar.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final TramiteSeguimiento seguimiento = await _repository
          .obtenerSeguimiento(usuarioId: usuarioId, instanciaId: instanciaId);

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        seguimiento: seguimiento,
        clearError: true,
      );
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cargar el seguimiento del tramite.',
      );
    }
  }
}
