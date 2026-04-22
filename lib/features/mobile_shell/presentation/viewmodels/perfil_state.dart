import '../../domain/models/perfil_usuario.dart';

class PerfilState {
  const PerfilState({
    required this.isLoading,
    required this.perfil,
    required this.mostrarDepartamento,
    this.lastLoadedUserId,
    this.errorMessage,
  });

  factory PerfilState.initial() {
    return const PerfilState(
      isLoading: false,
      perfil: null,
      mostrarDepartamento: false,
    );
  }

  final bool isLoading;
  final PerfilUsuario? perfil;
  final bool mostrarDepartamento;
  final String? lastLoadedUserId;
  final String? errorMessage;

  bool get isEmpty {
    return !isLoading && errorMessage == null && perfil == null;
  }

  PerfilState copyWith({
    bool? isLoading,
    PerfilUsuario? perfil,
    bool setPerfilNull = false,
    bool? mostrarDepartamento,
    String? lastLoadedUserId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PerfilState(
      isLoading: isLoading ?? this.isLoading,
      perfil: setPerfilNull ? null : (perfil ?? this.perfil),
      mostrarDepartamento: mostrarDepartamento ?? this.mostrarDepartamento,
      lastLoadedUserId: lastLoadedUserId ?? this.lastLoadedUserId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}