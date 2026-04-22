class MisTramiteItem {
  const MisTramiteItem({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.estado,
    required this.progreso,
    required this.actualizadoEn,
  });

  final String id;
  final String usuarioId;
  final String nombre;
  final String estado;
  final double progreso;
  final DateTime actualizadoEn;

  MisTramiteItem copyWith({
    String? id,
    String? usuarioId,
    String? nombre,
    String? estado,
    double? progreso,
    DateTime? actualizadoEn,
  }) {
    return MisTramiteItem(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      estado: estado ?? this.estado,
      progreso: progreso ?? this.progreso,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}