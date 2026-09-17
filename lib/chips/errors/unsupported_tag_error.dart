// Error de la etiqueta que no habla la tecnología que la app maneja.

import 'nfc_error.dart';

/// La etiqueta usa una tecnología de radio que la app no atiende.
class UnsupportedTagError extends NfcError {
  const UnsupportedTagError()
    : super(
        'Esta etiqueta no habla NfcA, así que la app no puede con ella.',
        details: 'La etiqueta no expone la tecnología NfcA.',
      );
}
