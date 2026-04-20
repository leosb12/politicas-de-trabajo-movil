class LoginRequestModel {
  const LoginRequestModel({
    required this.correo,
    required this.password,
  });

  final String correo;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'correo': correo,
      'password': password,
    };
  }
}
