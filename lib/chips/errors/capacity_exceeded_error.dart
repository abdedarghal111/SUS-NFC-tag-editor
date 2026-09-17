// Error del contenido que no cabe en la etiqueta.

import 'nfc_error.dart';

/// El contenido a grabar supera la capacidad de la etiqueta.
class CapacityExceededError extends NfcError {
  CapacityExceededError({required this.needed, required this.available})
    : super(
        'No cabe: hacen falta $needed bytes y la etiqueta tiene $available.',
        details: 'Capacidad según el CC de la página 3.',
      );

  /// Bytes que ocuparía el mensaje, relleno incluido.
  final int needed;

  /// Bytes de contenido que admite la etiqueta.
  final int available;
}
