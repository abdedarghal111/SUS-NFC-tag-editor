// Capacidad de exigir una contraseña antes de escribir.

import '../results/protection_result.dart';
import '../results/security_status.dart';

/// Protege la escritura con una contraseña, y permite ponerla y quitarla.
abstract interface class PasswordProtected {
  /// Lee el estado de la protección y, si procede, verifica la contraseña.
  Future<SecurityStatus> readSecurity({List<int> password});

  /// Graba la contraseña y protege a partir de [fromPage].
  Future<ProtectionResult> setPassword(
    List<int> password, {
    required int fromPage,
  });

  /// Quita la protección dejando la etiqueta abierta.
  Future<ProtectionResult> removePassword(List<int> password);
}
