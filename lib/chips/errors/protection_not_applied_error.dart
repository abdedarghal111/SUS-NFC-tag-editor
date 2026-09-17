// Error de la etiqueta que acepta el cambio de protección y no lo aplica.

import 'nfc_error.dart';

/// La etiqueta ha aceptado el comando pero AUTH0 no ha cambiado.
class ProtectionNotAppliedError extends NfcError {
  ProtectionNotAppliedError({
    required this.expected,
    required this.found,
    required this.offset,
    required String message,
  }) : super(
         message,
         details:
             'AUTH0 esperado en el byte $offset: $expected. '
             'CFG0 tras escribir: $found.',
       );

  /// Valor de AUTH0 que se quería dejar grabado.
  final int expected;

  /// CFG0 tal y como quedó, en hexadecimal.
  final String found;

  /// Byte de CFG0 donde se ha buscado AUTH0.
  final int offset;
}
