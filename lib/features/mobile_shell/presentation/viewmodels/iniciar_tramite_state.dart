import '../../domain/models/tramite_disponible_item.dart';

class IniciarTramiteState {
  const IniciarTramiteState({
    required this.isLoading,
    required this.tramites,
    required this.iniciandoTramiteIds,
    this.lastLoadedUserId,
    this.errorMessage,
  });

  factory IniciarTramiteState.initial() {
    return const IniciarTramiteState(
      isLoading: false,
      tramites: <TramiteDisponibleItem>[],
      iniciandoTramiteIds: <String>{},
    );
  }

  final bool isLoading;
  final List<TramiteDisponibleItem> tramites;
  final Set<String> iniciandoTramiteIds;
  final String? lastLoadedUserId;
  final String? errorMessage;

  bool get isEmpty {
    return !isLoading && errorMessage == null && tramites.isEmpty;
  }

  bool isIniciando(String tramiteId) {
    return iniciandoTramiteIds.contains(tramiteId);
  }

  IniciarTramiteState copyWith({
    bool? isLoading,
    List<TramiteDisponibleItem>? tramites,
    Set<String>? iniciandoTramiteIds,
    String? lastLoadedUserId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IniciarTramiteState(
      isLoading: isLoading ?? this.isLoading,
      tramites: tramites ?? this.tramites,
      iniciandoTramiteIds: iniciandoTramiteIds ?? this.iniciandoTramiteIds,
      lastLoadedUserId: lastLoadedUserId ?? this.lastLoadedUserId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}