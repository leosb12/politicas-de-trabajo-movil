import '../../domain/models/tramite_disponible_item.dart';

class IniciarTramiteState {
  const IniciarTramiteState({
    required this.isLoading,
    required this.isClassifying,
    required this.tramites,
    required this.iniciandoTramiteIds,
    this.lastLoadedUserId,
    this.errorMessage,
    this.classification,
    this.classificationError,
  });

  factory IniciarTramiteState.initial() {
    return const IniciarTramiteState(
      isLoading: false,
      isClassifying: false,
      tramites: <TramiteDisponibleItem>[],
      iniciandoTramiteIds: <String>{},
    );
  }

  final bool isLoading;
  final bool isClassifying;
  final List<TramiteDisponibleItem> tramites;
  final Set<String> iniciandoTramiteIds;
  final String? lastLoadedUserId;
  final String? errorMessage;
  final ClasificacionSolicitudResult? classification;
  final String? classificationError;

  bool get isEmpty {
    return !isLoading && errorMessage == null && tramites.isEmpty;
  }

  bool isIniciando(String tramiteId) {
    return iniciandoTramiteIds.contains(tramiteId);
  }

  IniciarTramiteState copyWith({
    bool? isLoading,
    bool? isClassifying,
    List<TramiteDisponibleItem>? tramites,
    Set<String>? iniciandoTramiteIds,
    String? lastLoadedUserId,
    String? errorMessage,
    ClasificacionSolicitudResult? classification,
    String? classificationError,
    bool clearError = false,
    bool clearClassification = false,
    bool clearClassificationError = false,
  }) {
    return IniciarTramiteState(
      isLoading: isLoading ?? this.isLoading,
      isClassifying: isClassifying ?? this.isClassifying,
      tramites: tramites ?? this.tramites,
      iniciandoTramiteIds: iniciandoTramiteIds ?? this.iniciandoTramiteIds,
      lastLoadedUserId: lastLoadedUserId ?? this.lastLoadedUserId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      classification: clearClassification
          ? null
          : (classification ?? this.classification),
      classificationError: clearClassificationError
          ? null
          : (classificationError ?? this.classificationError),
    );
  }
}
