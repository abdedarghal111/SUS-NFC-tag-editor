// Capacidad de extender la protección también a la lectura.

import '../results/protection_result.dart';

/// Permite que la contraseña haga falta además para leer.
abstract interface class ReadProtected {
  /// Activa o desactiva que la lectura pida contraseña.
  ///
  /// Hace falta la contraseña actual si la etiqueta ya está protegida.
  Future<ProtectionResult> setReadProtection(
    bool enabled, {
    List<int> password,
  });
}
