import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/perfil_usuario.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../../domain/services/perfil_visibilidad_policy.dart';
import 'perfil_state.dart';

class PerfilViewModel extends StateNotifier<PerfilState> {
  PerfilViewModel({
    required PerfilRepository repository,
    required PerfilVisibilidadPolicy visibilidadPolicy,
  }) : _repository = repository,
       _visibilidadPolicy = visibilidadPolicy,
       super(PerfilState.initial());

  final PerfilRepository _repository;
  final PerfilVisibilidadPolicy _visibilidadPolicy;

  Future<void> cargarPerfil({required String usuarioId}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final PerfilUsuario? perfil = await _repository.obtenerPerfil(
        usuarioId: usuarioId,
      );

      if (perfil == null) {
        state = state.copyWith(
          isLoading: false,
          setPerfilNull: true,
          mostrarDepartamento: false,
          lastLoadedUserId: usuarioId,
          clearError: true,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        perfil: perfil,
        mostrarDepartamento: _visibilidadPolicy.puedeMostrarDepartamento(
          perfil.rol,
        ),
        lastLoadedUserId: usuarioId,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        setPerfilNull: true,
        mostrarDepartamento: false,
        lastLoadedUserId: usuarioId,
        errorMessage: 'No se pudo cargar la información de perfil.',
      );
    }
  }
}