class TramiteDisponibleItem {
  const TramiteDisponibleItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    this.iniciado = false,
    this.requierePago = false,
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
      montoPago: montoPago ?? this.montoPago,
      monedaPago: monedaPago ?? this.monedaPago,
      descripcionPago: descripcionPago ?? this.descripcionPago,
    );
  }
}
