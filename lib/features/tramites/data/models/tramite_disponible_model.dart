import '../../domain/entities/tramite_disponible.dart';

class TramiteDisponibleModel {
  const TramiteDisponibleModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  final String id;
  final String nombre;
  final String? descripcion;

  factory TramiteDisponibleModel.fromJson(Map<String, dynamic> json) {
    return TramiteDisponibleModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
    );
  }

  TramiteDisponible toEntity() {
    return TramiteDisponible(id: id, nombre: nombre, descripcion: descripcion);
  }
}
