// Errores de las operaciones NFC y traducción de los fallos nativos.

/// Error de una operación NFC, con mensaje para el usuario y detalle técnico.
class NfcError implements Exception {
  const NfcError(this.message, {this.details = ''});

  /// Explicación en lenguaje llano, pensada para enseñarla en pantalla.
  final String message;

  /// Volcado técnico: excepción original, bytes o contexto para diagnosticar.
  final String details;

  /// Traduce una excepción de la capa nativa a un [NfcError] entendible.
  factory NfcError.from(Object error) {
    final details = error.toString();
    if (isConnectionLost(error)) {
      return NfcError(
        'Se ha perdido la conexión con la etiqueta antes de terminar. '
        'Déjala quieta sobre el teléfono y prueba otra vez.',
        details: details,
      );
    }
    if (details.contains('Transceive failed') ||
        details.contains('IOException')) {
      return NfcError(
        'La etiqueta ha rechazado el comando o se ha separado antes de tiempo. '
        'Si es un rechazo, suele ser que la zona está protegida y la '
        'contraseña no es la correcta.',
        details: details,
      );
    }
    return NfcError(
      'Algo ha fallado al hablar con la etiqueta.',
      details: details,
    );
  }

  /// Indica si la excepción es una caída de conexión y no un rechazo.
  static bool isConnectionLost(Object error) =>
      error.toString().contains('TagLostException');

  @override
  String toString() => message;
}
