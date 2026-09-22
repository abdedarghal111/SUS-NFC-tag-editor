// Error de la escritura que la etiqueta rechaza por estar protegida.

import '../dictionaries/ntag_protocol.dart';
import 'nfc_error.dart';

/// La etiqueta ha rechazado escribir porque está protegida con contraseña.
class WriteRejectedError extends NfcError {
  WriteRejectedError({required this.operation, required String cause})
    : super(
        'La etiqueta está protegida con contraseña y ha rechazado $operation. '
        'Quítale la contraseña para poder escribir.',
        details: [explainRejection(NtagCommand.write), '', cause].join('\n'),
      );

  /// Operación que la etiqueta ha rechazado.
  final String operation;
}
