class TramiteDisponible {
  const TramiteDisponible({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipoPolitica,
    required this.departamentoInicioId,
    required this.departamentoInicioNombre,
    this.requierePago = false,
    this.montoPago,
    this.monedaPago,
    this.descripcionPago,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String tipoPolitica;
  final String? departamentoInicioId;
  final String? departamentoInicioNombre;
  final bool requierePago;
  final double? montoPago;
  final String? monedaPago;
  final String? descripcionPago;
}
