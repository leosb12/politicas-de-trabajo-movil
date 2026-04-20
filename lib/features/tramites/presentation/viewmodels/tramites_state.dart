import '../../domain/entities/instancia_iniciada.dart';
import '../../domain/entities/tramite_disponible.dart';

class TramitesState {
  const TramitesState({
    required this.isLoading,
    required this.tramites,
    required this.startingTramiteId,
    required this.errorMessage,
    required this.successMessage,
    required this.ultimaInstanciaIniciada,
  });

  factory TramitesState.initial() {
    return const TramitesState(
      isLoading: false,
      tramites: <TramiteDisponible>[],
      startingTramiteId: null,
      errorMessage: null,
      successMessage: null,
      ultimaInstanciaIniciada: null,
    );
  }

  final bool isLoading;
  final List<TramiteDisponible> tramites;
  final String? startingTramiteId;
  final String? errorMessage;
  final String? successMessage;
  final InstanciaIniciada? ultimaInstanciaIniciada;

  bool get isStartingAny => startingTramiteId != null;

  TramitesState copyWith({
    bool? isLoading,
    List<TramiteDisponible>? tramites,
    String? startingTramiteId,
    bool clearStartingTramiteId = false,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    InstanciaIniciada? ultimaInstanciaIniciada,
    bool clearUltimaInstanciaIniciada = false,
  }) {
    return TramitesState(
      isLoading: isLoading ?? this.isLoading,
      tramites: tramites ?? this.tramites,
      startingTramiteId: clearStartingTramiteId
          ? null
          : (startingTramiteId ?? this.startingTramiteId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      ultimaInstanciaIniciada: clearUltimaInstanciaIniciada
          ? null
          : (ultimaInstanciaIniciada ?? this.ultimaInstanciaIniciada),
    );
  }
}
