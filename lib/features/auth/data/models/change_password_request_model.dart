class ChangePasswordRequestModel {
  const ChangePasswordRequestModel({
    required this.correo,
    required this.passwordActual,
    required this.nuevaContrasena,
    required this.confirmarNuevaContrasena,
  });

  final String correo;
  final String passwordActual;
  final String nuevaContrasena;
  final String confirmarNuevaContrasena;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'correo': correo,
      'passwordActual': passwordActual,
      'nuevaContrasena': nuevaContrasena,
      'confirmarNuevaContrasena': confirmarNuevaContrasena,
    };
  }
}