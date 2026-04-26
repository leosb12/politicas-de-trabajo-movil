class MisTramiteItem {
  const MisTramiteItem({
    required this.id,
    required this.usuarioId,
    required this.codigoTramite,
    required this.nombre,
    required this.estado,
    required this.progreso,
    required this.fechaCreacion,
  });

  final String id;
  final String usuarioId;
  final String codigoTramite;
  final String nombre;
  final String estado;
  final double progreso;
  final DateTime fechaCreacion;

  MisTramiteItem copyWith({
    String? id,
    String? usuarioId,
    String? codigoTramite,
    String? nombre,
    String? estado,
    double? progreso,
    DateTime? fechaCreacion,
  }) {
    return MisTramiteItem(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      codigoTramite: codigoTramite ?? this.codigoTramite,
      nombre: nombre ?? this.nombre,
      estado: estado ?? this.estado,
      progreso: progreso ?? this.progreso,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
