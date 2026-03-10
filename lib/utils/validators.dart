class Validators {
  /// Valida que el correo sea institucional
  static bool isInstitutionalEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@est\.umss\.edu$');
    return regex.hasMatch(email);
  }

  /// Valida que el campo no esté vacío
  static bool isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  /// Valida contraseñas mínimas
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Mensajes de error listos para usar
  static String? emailError(String email) {
    if (!isNotEmpty(email)) return "El correo no puede estar vacío";
    if (!isInstitutionalEmail(email)) return "Debe ser un correo institucional";
    return null;
  }

  static String? passwordError(String password) {
    if (!isNotEmpty(password)) return "La contraseña no puede estar vacía";
    if (!isValidPassword(password)) return "Debe tener al menos 6 caracteres";
    return null;
  }
}
