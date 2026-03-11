const String kAdminEmail = 'administrador.metroswap@correo.unimet.edu.ve';

bool isAdminEmail(String? email) {
  final normalized = email?.trim().toLowerCase() ?? '';
  return normalized == kAdminEmail;
}

String normalizeUserStatus(dynamic rawStatus) {
  final normalized = rawStatus?.toString().trim().toLowerCase() ?? '';
  if (normalized == 'suspendido' || normalized == 'suspended') {
    return 'Suspendido';
  }
  return 'Activo';
}

bool isSuspendedUserStatus(dynamic rawStatus) {
  return normalizeUserStatus(rawStatus) == 'Suspendido';
}
