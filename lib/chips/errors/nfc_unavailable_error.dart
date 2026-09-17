// Error del teléfono que no puede usar el NFC.

import 'nfc_error.dart';

/// El NFC está apagado o el teléfono no lo tiene.
class NfcUnavailableError extends NfcError {
  const NfcUnavailableError()
    : super(
        'El NFC está apagado o este teléfono no lo soporta.',
        details: 'checkAvailability no ha devuelto enabled.',
      );
}
