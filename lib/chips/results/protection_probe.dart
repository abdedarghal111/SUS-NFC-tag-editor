// Veredicto sobre si la etiqueta aplica la protección que declara.

import '../../utils/hex.dart';
import 'tag_result.dart';
import '../../chips/type2/auth0_layout.dart';
import '../../chips/type2/type2_chip.dart';

/// Veredicto sobre si la etiqueta aplica de verdad la protección que declara.
class ProtectionProbe extends TagResult {
  const ProtectionProbe({
    required this.config,
    required this.layout,
    required this.writeAccepted,
  });

  /// Los 4 bytes de CFG0 tal y como los devuelve la etiqueta.
  final List<int> config;

  /// Posición de AUTH0 que se ha usado para interpretar CFG0.
  final Auth0Layout layout;

  final bool writeAccepted;

  /// Valor de AUTH0 según la posición elegida.
  int get auth0 => config[layout.offset];

  bool get claimsProtection => auth0 != Type2Chip.noProtection;

  bool get isConsistent => claimsProtection != writeAccepted;

  /// Explica el resultado de la prueba en lenguaje llano.
  String get verdict {
    if (claimsProtection && !writeAccepted) {
      return 'Protección real: la etiqueta ha rechazado escribir sin '
          'contraseña.';
    }
    if (claimsProtection && writeAccepted) {
      return 'Protección falsa: CFG0 dice que está bloqueada, pero ha dejado '
          'escribir sin contraseña. Con esta posición de AUTH0 el chip no se '
          'entera; prueba la otra.';
    }
    if (!claimsProtection && writeAccepted) {
      return 'Sin protección, como declara CFG0.';
    }
    return 'Raro: CFG0 dice que no hay protección pero ha rechazado la '
        'escritura. Puede estar bloqueada de fábrica.';
  }

  @override
  String get summary =>
      'CFG0 ${hexBytes(config)}, AUTH0 ${hexByte(auth0)}: '
      '${writeAccepted ? 'deja escribir' : 'rechaza escribir'} sin contraseña.';
}
