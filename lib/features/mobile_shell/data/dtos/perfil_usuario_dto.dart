class PerfilUsuarioDto {
  const PerfilUsuarioDto({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.departamentoId,
  });

  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final String? departamentoId;

  factory PerfilUsuarioDto.fromJson(Map<String, dynamic> json) {
    return PerfilUsuarioDto(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
      departamentoId: json['departamentoId'] as String?,
    );
  }
}