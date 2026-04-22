class PerfilUsuario {
  const PerfilUsuario({
    required this.usuarioId,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.departamento,
  });

  final String usuarioId;
  final String nombre;
  final String correo;
  final String rol;
  final String? departamento;

  PerfilUsuario copyWith({
    String? usuarioId,
    String? nombre,
    String? correo,
    String? rol,
    String? departamento,
  }) {
    return PerfilUsuario(
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      departamento: departamento ?? this.departamento,
    );
  }
}