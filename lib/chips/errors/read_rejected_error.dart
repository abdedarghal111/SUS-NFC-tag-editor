// Error de la lectura que la etiqueta rechaza por tenerla protegida.

import '../dictionaries/ntag_protocol.dart';
import 'nfc_error.dart';

/// La etiqueta ha rechazado leer, lo que apunta a protección de lectura.
///
/// Con la lectura protegida no se puede mirar ni la configuración, así que no
/// hay forma de confirmarlo sin autenticarse antes.
class ReadRejectedError extends NfcError {
  ReadRejectedError({
    required this.authenticated,
    required String cause,
    NtagCommand command = NtagCommand.read,
  }) : super(
         authenticated
             ? 'La etiqueta ha rechazado leer aun con la contraseña. O no es '
                   'la suya, o la protección de lectura no la levanta.'
             : 'La etiqueta ha rechazado leer: tiene la lectura protegida. '
                   'Usa «Leer con contraseña» para entrar con ella, o '
                   '«Dejar leer sin contraseña» para quitar esa protección.',
         details: [
           explainRejection(command, authenticated: authenticated),
           '',
           cause,
         ].join('\n'),
       );

  /// Indica si se llegó a enviar una contraseña antes de leer.
  final bool authenticated;
}
