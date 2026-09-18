// Error de la etiqueta cuyo modelo no está en el catálogo.

import 'nfc_error.dart';

/// La etiqueta no dice qué modelo es, o dice uno que no está en el catálogo.
class UnknownChipError extends NfcError {
  const UnknownChipError()
    : super(
        'Esta etiqueta no dice qué modelo es. Elígelo a mano para trabajar '
        'con ella; con los clones pasa a menudo.',
        details: 'GET_VERSION no ha devuelto un modelo del catálogo.',
      );
}
