class TramiteDisponibleItem {
  const TramiteDisponibleItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    this.iniciado = false,
    this.requierePago = false,
    this.tieneRequisitosIniciales = false,
    this.montoPago,
    this.monedaPago,
    this.descripcionPago,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final bool iniciado;
  final bool requierePago;
  final bool tieneRequisitosIniciales;
  final double? montoPago;
  final String? monedaPago;
  final String? descripcionPago;

  TramiteDisponibleItem copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? categoria,
    bool? iniciado,
    bool? requierePago,
    bool? tieneRequisitosIniciales,
    double? montoPago,
    String? monedaPago,
    String? descripcionPago,
  }) {
    return TramiteDisponibleItem(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      iniciado: iniciado ?? this.iniciado,
      requierePago: requierePago ?? this.requierePago,
      tieneRequisitosIniciales:
          tieneRequisitosIniciales ?? this.tieneRequisitosIniciales,
      montoPago: montoPago ?? this.montoPago,
      monedaPago: monedaPago ?? this.monedaPago,
      descripcionPago: descripcionPago ?? this.descripcionPago,
    );
  }
}

class ClasificacionSolicitudItem {
  const ClasificacionSolicitudItem({
    required this.politicaId,
    required this.nombrePolitica,
    required this.confianza,
    this.scoreRequisitos,
    this.scoreSemantico,
    this.scoreFinal,
    this.requisitosCoincidentes = const <String>[],
    this.requisitosFaltantes = const <String>[],
  });

  final String politicaId;
  final String nombrePolitica;
  final double confianza;
  final double? scoreRequisitos;
  final double? scoreSemantico;
  final double? scoreFinal;
  final List<String> requisitosCoincidentes;
  final List<String> requisitosFaltantes;
}

class ClasificacionSolicitudResult {
  const ClasificacionSolicitudResult({
    required this.politicaId,
    required this.nombrePolitica,
    required this.confianza,
    required this.origen,
    required this.requiereMasInformacion,
    required this.requiereConfirmacion,
    required this.mensaje,
    required this.topResultados,
    this.descripcionPolitica,
    this.metodoRecomendacion,
    this.requisitosDetectados = const <String>[],
    this.requisitosCoincidentes = const <String>[],
    this.requisitosFaltantes = const <String>[],
    this.scoreRequisitos,
    this.scoreSemantico,
    this.scoreFinal,
  });

  final String politicaId;
  final String nombrePolitica;
  final String? descripcionPolitica;
  final double confianza;
  final String origen;
  final String? metodoRecomendacion;
  final bool requiereMasInformacion;
  final bool requiereConfirmacion;
  final String mensaje;
  final List<String> requisitosDetectados;
  final List<String> requisitosCoincidentes;
  final List<String> requisitosFaltantes;
  final double? scoreRequisitos;
  final double? scoreSemantico;
  final double? scoreFinal;
  final List<ClasificacionSolicitudItem> topResultados;
}
