class RegisterRequestModel {
  const RegisterRequestModel({
    required this.nombre,
    required this.correo,
    required this.password,
  });

  final String nombre;
  final String correo;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': nombre,
      'correo': correo,
      'password': password,
    };
  }
}
