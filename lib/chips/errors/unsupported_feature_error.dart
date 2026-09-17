// Error de la operación que el chip no sabe hacer.

import 'nfc_error.dart';

/// Se ha pedido al chip algo que su modelo no soporta.
///
/// La interfaz esconde lo que el chip no implementa, así que este error avisa
/// de un fallo de programación más que de un descuido del usuario.
class UnsupportedFeatureError extends NfcError {
  UnsupportedFeatureError(this.chipName, this.feature)
    : super(
        'El $chipName no admite $feature.',
        details: '$chipName no implementa la interfaz de $feature.',
      );

  /// Modelo que ha rechazado la operación.
  final String chipName;

  /// Funcionalidad que se le ha pedido.
  final String feature;
}
