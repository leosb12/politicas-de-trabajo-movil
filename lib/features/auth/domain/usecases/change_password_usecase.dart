import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String correo,
    required String passwordActual,
    required String nuevaContrasena,
    required String confirmarNuevaContrasena,
  }) {
    return _repository.changePassword(
      correo: correo,
      passwordActual: passwordActual,
      nuevaContrasena: nuevaContrasena,
      confirmarNuevaContrasena: confirmarNuevaContrasena,
    );
  }
}