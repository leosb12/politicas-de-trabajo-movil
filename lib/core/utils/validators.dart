class Validators {
  const Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }

    const String emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(emailPattern).hasMatch(value.trim())) {
      return 'Ingresa un correo valido';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contrasena es obligatoria';
    }

    if (value.length < 4) {
      return 'La contrasena debe tener al menos 4 caracteres';
    }

    return null;
  }
}
