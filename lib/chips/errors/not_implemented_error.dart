// Error de la operación que el modelo admite pero la app aún no sabe hacer.

import 'nfc_error.dart';

/// El chip soporta esta operación, pero todavía no está escrita en la app.
///
/// Se distingue de [UnsupportedFeatureError], que es para operaciones que el
/// modelo no admite de ninguna manera.
class NotImplementedError extends NfcError {
  NotImplementedError(this.chipName, this.feature)
    : super(
        'Todavía no está hecho: $feature en $chipName.',
        details: '$chipName declara $feature pero la app no lo implementa.',
      );

  /// Modelo al que se le ha pedido la operación.
  final String chipName;

  /// Operación que falta por escribir.
  final String feature;
}
