// Error de la contraseña que la etiqueta no acepta al autenticarse.

import 'nfc_error.dart';

/// La etiqueta ha rechazado la contraseña al verificarla con PWD_AUTH.
///
/// Una etiqueta sin contraseña puesta también rechaza: de fábrica guarda
/// `FF FF FF FF` y compara contra eso.
class PasswordRejectedError extends NfcError {
  PasswordRejectedError({required String cause})
    : super(
        'La etiqueta ha rechazado la contraseña. Si no tiene ninguna puesta, '
        'léela con «Leer la etiqueta», sin contraseña.',
        details: cause,
      );
}
