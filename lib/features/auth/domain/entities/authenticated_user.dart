class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.departamentoId,
    this.token,
  });

  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final String? departamentoId;
  final String? token;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'departamentoId': departamentoId,
      'token': token,
    };
  }

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
      departamentoId: json['departamentoId'] as String?,
      token: json['token'] as String?,
    );
  }
}
