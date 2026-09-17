// Error de la etiqueta que no es la que se esperaba.

import 'nfc_error.dart';

/// La etiqueta que hay delante no es aquella con la que se creó el chip.
///
/// Salta en la comprobación previa a cada operación: seguir adelante escribiría
/// en una etiqueta distinta de la que el usuario cree tener.
class ChipMismatchError extends NfcError {
  ChipMismatchError({required this.expectedUid, required this.foundUid})
    : super(
        'Esta no es la misma etiqueta. Separa la actual y vuelve a acercar '
        'la de antes.',
        details: 'UID esperado $expectedUid, encontrado $foundUid.',
      );

  /// UID de la etiqueta con la que se creó el chip.
  final String expectedUid;

  /// UID de la etiqueta que hay ahora en el campo.
  final String foundUid;
}
