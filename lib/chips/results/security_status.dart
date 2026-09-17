// Estado de la protección leído de las páginas de configuración.

import '../../utils/hex.dart';
import 'tag_result.dart';
import '../../chips/type2/auth0_layout.dart';
import '../../chips/type2/type2_chip.dart';

class SecurityStatus extends TagResult {
  const SecurityStatus({
    required this.config,
    required this.layout,
    required this.access,
    required this.storedPassword,
    required this.storedPack,
    required this.passwordChecked,
    required this.passwordCorrect,
  });

  /// Los 4 bytes de CFG0 tal y como los devuelve la etiqueta.
  final List<int> config;

  /// Posición de AUTH0 con la que se interpreta CFG0.
  final Auth0Layout layout;

  /// Primera página protegida; 0xFF significa que no hay protección.
  int get auth0 => config[layout.offset];

  /// Byte ACCESS: el bit 7 es PROT y los bits 0-2 son AUTHLIM.
  final int access;

  final List<int> storedPassword;

  final List<int> storedPack;

  final bool passwordChecked;

  final bool passwordCorrect;

  bool get isLocked => auth0 != Type2Chip.noProtection;

  bool get protectsReading => access & Type2Chip.protectReadMask != 0;

  /// Número de fallos tolerados antes del bloqueo permanente; 0 es ilimitado.
  int get failedAttemptsLimit => access & Type2Chip.authLimitMask;

  /// Indica si la etiqueta deja leer su propia contraseña, lo que invalida la
  /// protección.
  bool get leaksPassword =>
      storedPassword.any((byte) => byte != 0) ||
      storedPack.any((byte) => byte != 0);

  String get scope {
    if (!isLocked) return 'Sin contraseña.';
    if (auth0 == 0) {
      return 'Bloqueada entera desde la página 0: hasta la configuración está '
          'protegida.';
    }
    return 'Protegida desde la página $auth0.';
  }

  @override
  String get summary => isLocked
      ? 'Etiqueta bloqueada (AUTH0 ${hexByte(auth0)}).'
      : 'Etiqueta sin contraseña.';
}
