import '../../domain/models/mis_tramite_item.dart';

class MisTramitesState {
  const MisTramitesState({
    required this.isLoading,
    required this.tramites,
    this.lastLoadedUserId,
    this.errorMessage,
  });

  factory MisTramitesState.initial() {
    return const MisTramitesState(
      isLoading: false,
      tramites: <MisTramiteItem>[],
    );
  }

  final bool isLoading;
  final List<MisTramiteItem> tramites;
  final String? lastLoadedUserId;
  final String? errorMessage;

  bool get isEmpty {
    return !isLoading && errorMessage == null && tramites.isEmpty;
  }

  MisTramitesState copyWith({
    bool? isLoading,
    List<MisTramiteItem>? tramites,
    String? lastLoadedUserId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MisTramitesState(
      isLoading: isLoading ?? this.isLoading,
      tramites: tramites ?? this.tramites,
      lastLoadedUserId: lastLoadedUserId ?? this.lastLoadedUserId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}