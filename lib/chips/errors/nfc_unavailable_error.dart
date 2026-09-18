// Error del NFC que no se puede usar: apagado o sin lector en el teléfono.

import 'nfc_error.dart';

/// El NFC no se puede usar, por falta de lector o porque está apagado.
class NfcUnavailableError extends NfcError {
  /// El teléfono tiene NFC y está apagado.
  const NfcUnavailableError.disabled()
    : canBeEnabled = true,
      super(
        'El NFC está apagado. Actívalo para leer la etiqueta.',
        details: 'checkAvailability ha devuelto disabled.',
      );

  /// El teléfono no tiene lector NFC.
  const NfcUnavailableError.unsupported()
    : canBeEnabled = false,
      super(
        'Este teléfono no tiene lector NFC.',
        details: 'checkAvailability ha devuelto unsupported.',
      );

  /// Indica si basta con activar el NFC en los ajustes del sistema.
  final bool canBeEnabled;
}
