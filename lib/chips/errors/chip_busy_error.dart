// Error de la operación que llega mientras el chip atiende otra.

import 'nfc_error.dart';

/// Se ha pedido una operación al chip sin que la anterior haya terminado.
class ChipBusyError extends NfcError {
  ChipBusyError(this.chipName)
    : super(
        'Espera a que termine la operación anterior.',
        details: '$chipName está atendiendo otra operación.',
      );

  /// Modelo que está ocupado.
  final String chipName;
}
