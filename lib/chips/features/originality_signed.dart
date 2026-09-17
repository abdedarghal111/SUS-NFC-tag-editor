// Capacidad de demostrar de qué fábrica salió el silicio.

/// Entrega la firma que el fabricante grabó sobre el UID del chip.
///
/// Una firma que no cuadra con la clave pública del fabricante descarta el
/// chip como original.
abstract interface class OriginalitySigned {
  /// Lee la firma de fábrica; vacía si la etiqueta no la entrega.
  Future<List<int>> readOriginalitySignature();
}
