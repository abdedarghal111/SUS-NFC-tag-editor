// Estado de la protección leído de las páginas de configuración.

import '../../utils/hex.dart';
import 'tag_result.dart';
import '../../chips/type2/type2_chip.dart';

/// Protección que tiene puesta la etiqueta y hasta dónde llega.
///
/// Reúne lo leído de las páginas de configuración y lo traduce a respuestas
/// directas: si está bloqueada, qué alcanza la contraseña y si la filtra.
class SecurityStatus extends TagResult {
  const SecurityStatus({
    required this.config,
    required this.access,
    required this.storedPassword,
    required this.storedPack,
    required this.passwordChecked,
    required this.passwordCorrect,
  });

  /// Los 4 bytes de CFG0 tal y como los devuelve la etiqueta.
  final List<int> config;

  /// Primera página protegida; 0xFF significa que no hay protección.
  int get auth0 => config[Type2Chip.auth0Offset];

  /// Byte ACCESS: el bit 7 es PROT y los bits 0-2 son AUTHLIM.
  final int access;

  /// Contraseña que la etiqueta ha dejado leer; vacía o a cero si no la filtra.
  final List<int> storedPassword;

  /// Acuse PACK que la etiqueta ha dejado leer, junto a la contraseña.
  final List<int> storedPack;

  /// Indica si se ha llegado a probar la contraseña contra la etiqueta.
  final bool passwordChecked;

  /// Indica si la contraseña probada era la buena.
  final bool passwordCorrect;

  /// Indica si la etiqueta tiene protección puesta.
  bool get isLocked => auth0 != Type2Chip.noProtection;

  /// Indica si la protección alcanza también a la lectura, no solo a la
  /// escritura.
  bool get protectsReading =>
      isLocked && access & Type2Chip.protectReadMask != 0;

  /// Indica si el bit PROT está puesto, aplique o no.
  ///
  /// Sin AUTH0 protegiendo nada el bit se queda escrito pero no impide nada.
  /// Sirve para avisar de que la próxima contraseña tapará también la
  /// lectura.
  bool get readProtectionArmed => access & Type2Chip.protectReadMask != 0;

  /// Número de fallos tolerados antes del bloqueo permanente; 0 es ilimitado.
  int get failedAttemptsLimit => access & Type2Chip.authLimitMask;

  /// Indica si la etiqueta deja leer su propia contraseña, lo que invalida la
  /// protección.
  bool get leaksPassword =>
      storedPassword.any((byte) => byte != 0) ||
      storedPack.any((byte) => byte != 0);

  /// Explica en lenguaje llano hasta dónde llega la protección.
  String get scope {
    if (!isLocked) {
      return 'Sin contraseña: cualquiera puede cambiar lo que tiene grabado.';
    }
    if (auth0 == 0) {
      return 'Protegida del todo: ni el contenido ni su configuración se '
          'pueden tocar sin la contraseña.';
    }
    return 'Sin la contraseña no se puede cambiar lo que tiene grabado.';
  }

  @override
  String get summary => isLocked
      ? 'Etiqueta bloqueada (AUTH0 ${hexByte(auth0)}).'
      : 'Etiqueta sin contraseña.';
}
