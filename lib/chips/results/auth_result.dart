// Resultado de autenticar contra una etiqueta protegida por contraseña.

import '../../utils/hex.dart';
import 'tag_result.dart';

/// Respuesta de la etiqueta a una autenticación con contraseña.
class AuthResult extends TagResult {
  const AuthResult.accepted(this.pack)
    : wasProtected = true,
      authenticated = true;

  const AuthResult.notProtected()
    : pack = const [],
      wasProtected = false,
      authenticated = false;

  /// La zona está protegida pero no se autorizó usar la contraseña.
  const AuthResult.skipped()
    : pack = const [],
      wasProtected = true,
      authenticated = false;

  /// PACK devuelto por la etiqueta; vacío si no se llegó a autenticar.
  final List<int> pack;

  final bool wasProtected;
  final bool authenticated;

  @override
  String get summary {
    if (authenticated) {
      return 'Contraseña aceptada (PACK ${hexBytes(pack)}).';
    }
    return wasProtected
        ? 'Zona protegida; se ha entrado sin contraseña.'
        : 'Esa zona no está protegida.';
  }
}
