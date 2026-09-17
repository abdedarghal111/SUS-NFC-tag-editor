// Error de la acción que llega con el lector ya ocupado.

import 'nfc_error.dart';

/// Ya hay una acción esperando etiqueta o ejecutándose.
class ReaderBusyError extends NfcError {
  const ReaderBusyError()
    : super(
        'Ya hay una acción en marcha.',
        details: 'El lector tiene una acción pendiente sin terminar.',
      );
}
