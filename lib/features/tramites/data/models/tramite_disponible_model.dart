import '../../domain/entities/tramite_disponible.dart';

class TramiteDisponibleModel {
  const TramiteDisponibleModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipoPolitica,
    required this.departamentoInicioId,
    required this.departamentoInicioNombre,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String tipoPolitica;
  final String? departamentoInicioId;
  final String? departamentoInicioNombre;

  factory TramiteDisponibleModel.fromJson(Map<String, dynamic> json) {
    return TramiteDisponibleModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      tipoPolitica: json['tipoPolitica'] as String? ?? 'EXTERNA',
      departamentoInicioId: json['departamentoInicioId'] as String?,
      departamentoInicioNombre: json['departamentoInicioNombre'] as String?,
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
    );
  }
}
