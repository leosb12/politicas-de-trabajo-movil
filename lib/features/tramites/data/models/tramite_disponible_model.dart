import '../../domain/entities/tramite_disponible.dart';

class TramiteDisponibleModel {
  const TramiteDisponibleModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipoPolitica,
    required this.departamentoInicioId,
    required this.departamentoInicioNombre,
    required this.requierePago,
    required this.tieneRequisitosIniciales,
    required this.montoPago,
    required this.monedaPago,
    required this.descripcionPago,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String tipoPolitica;
  final String? departamentoInicioId;
  final String? departamentoInicioNombre;
  final bool requierePago;
  final bool tieneRequisitosIniciales;
  final double? montoPago;
  final String? monedaPago;
  final String? descripcionPago;

  factory TramiteDisponibleModel.fromJson(Map<String, dynamic> json) {
    return TramiteDisponibleModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      tipoPolitica: json['tipoPolitica'] as String? ?? 'EXTERNA',
      departamentoInicioId: json['departamentoInicioId'] as String?,
      departamentoInicioNombre: json['departamentoInicioNombre'] as String?,
      requierePago: json['requierePago'] as bool? ?? false,
      tieneRequisitosIniciales: json['tieneRequisitosIniciales'] as bool? ?? false,
      montoPago: _readMontoPago(json['montoPago']),
      monedaPago: json['monedaPago'] as String?,
      descripcionPago: json['descripcionPago'] as String?,
    );
  }

  TramiteDisponible toEntity() {
    return TramiteDisponible(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      tipoPolitica: tipoPolitica,
      departamentoInicioId: departamentoInicioId,
      departamentoInicioNombre: departamentoInicioNombre,
      requierePago: requierePago,
      tieneRequisitosIniciales: tieneRequisitosIniciales,
      montoPago: montoPago,
      monedaPago: monedaPago,
      descripcionPago: descripcionPago,
    );
  }

  static double? _readMontoPago(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}
