import 'package:flutter_test/flutter_test.dart';
import 'package:metroswap/utils/admin_utils.dart';

void main() {
  group('admin utils', () {
    test('isAdminEmail validates canonical admin account', () {
      expect(isAdminEmail('administrador.metroswap@correo.unimet.edu.ve'), isTrue);
      expect(isAdminEmail(' ADMINISTRADOR.METROSWAP@CORREO.UNIMET.EDU.VE '), isTrue);
      expect(isAdminEmail('usuario@correo.unimet.edu.ve'), isFalse);
    });

    test('normalizeUserStatus handles english/spanish and defaults active', () {
      expect(normalizeUserStatus('Suspendido'), 'Suspendido');
      expect(normalizeUserStatus('suspended'), 'Suspendido');
      expect(normalizeUserStatus('ACTIVO'), 'Activo');
      expect(normalizeUserStatus(null), 'Activo');
    });

    test('isSuspendedUserStatus reflects normalized value', () {
      expect(isSuspendedUserStatus('Suspendido'), isTrue);
      expect(isSuspendedUserStatus('suspended'), isTrue);
      expect(isSuspendedUserStatus('Activo'), isFalse);
    });
  });
}
