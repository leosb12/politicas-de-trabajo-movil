import '../../domain/entities/authenticated_user.dart';

class LoginResponseModel {
  const LoginResponseModel({
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

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
      departamentoId: json['departamentoId'] as String?,
      token: json['token'] as String?,
    );
  }

  AuthenticatedUser toEntity() {
    return AuthenticatedUser(
      id: id,
      nombre: nombre,
      correo: correo,
      rol: rol,
      departamentoId: departamentoId,
      token: token,
    );
  }
}
