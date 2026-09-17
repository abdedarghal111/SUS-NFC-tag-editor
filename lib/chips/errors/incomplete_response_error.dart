// Error de la etiqueta que contesta menos bytes de los debidos.

import 'nfc_error.dart';

/// La etiqueta ha devuelto una respuesta más corta de lo que exige el comando.
class IncompleteResponseError extends NfcError {
  IncompleteResponseError({
    required this.command,
    required this.expected,
    required this.received,
  }) : super(
         'La etiqueta no ha devuelto la respuesta completa.',
         details: '$command devolvió $received bytes y hacían falta $expected.',
       );

  /// Comando enviado, con el nombre que sale en la traza.
  final String command;

  /// Bytes que se esperaban.
  final int expected;

  /// Bytes que llegaron.
  final int received;
}
