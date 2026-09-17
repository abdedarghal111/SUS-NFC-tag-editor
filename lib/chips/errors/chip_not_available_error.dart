// Error del modelo reconocido pero sin operaciones escritas.

import 'nfc_error.dart';

/// La app reconoce el modelo pero todavía no sabe trabajar con él.
class ChipNotAvailableError extends NfcError {
  ChipNotAvailableError(this.chipName)
    : super(
        'La app reconoce esta etiqueta como $chipName, pero todavía no sabe '
        'trabajar con ese modelo.',
        details: '$chipName está en el catálogo con enabled en false.',
      );

  /// Modelo detectado.
  final String chipName;
}
