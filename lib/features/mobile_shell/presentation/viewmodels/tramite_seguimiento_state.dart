import '../../domain/models/tramite_seguimiento.dart';

class TramiteSeguimientoState {
  const TramiteSeguimientoState({
    required this.isLoading,
    this.seguimiento,
    this.errorMessage,
  });

  factory TramiteSeguimientoState.initial() {
    return const TramiteSeguimientoState(isLoading: false);
  }

  final bool isLoading;
  final TramiteSeguimiento? seguimiento;
  final String? errorMessage;

  bool get isEmpty {
    return !isLoading &&
        errorMessage == null &&
        seguimiento != null &&
        seguimiento!.isEmpty;
  }

  TramiteSeguimientoState copyWith({
    bool? isLoading,
    TramiteSeguimiento? seguimiento,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TramiteSeguimientoState(
      isLoading: isLoading ?? this.isLoading,
      seguimiento: seguimiento ?? this.seguimiento,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
