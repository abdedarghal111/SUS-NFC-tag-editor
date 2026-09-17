// Resultado de activar o desactivar la protección de la etiqueta.

import 'tag_result.dart';
import '../../chips/type2/type2_chip.dart';

/// Resultado de cambiar la protección: el AUTH0 que ha quedado grabado.
class ProtectionResult extends TagResult {
  const ProtectionResult(this.auth0);

  /// Valor de AUTH0 releído de la etiqueta tras el cambio.
  final int auth0;

  bool get isLocked => auth0 != Type2Chip.noProtection;

  @override
  String get summary => isLocked
      ? 'Contraseña activa: protegido desde la página $auth0.'
      : 'Contraseña quitada: la etiqueta queda libre.';
}
