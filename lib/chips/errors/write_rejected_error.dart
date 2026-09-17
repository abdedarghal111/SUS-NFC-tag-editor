// Error de la escritura que la etiqueta rechaza por estar protegida.

import 'nfc_error.dart';

/// La etiqueta ha rechazado escribir y no se había autorizado la contraseña.
class WriteRejectedError extends NfcError {
  WriteRejectedError({required this.operation, required String cause})
    : super(
        'La etiqueta está protegida y no has autorizado usar la contraseña, '
        'así que ha rechazado $operation.',
        details: cause,
      );

  /// Operación que la etiqueta ha rechazado.
  final String operation;
}
