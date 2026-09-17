// Capacidad de llevar la cuenta de las veces que se ha leído.

/// Expone un contador que el chip incrementa solo y que nunca decrece.
abstract interface class Counted {
  /// Lee el contador de lecturas de la etiqueta.
  ///
  /// Devuelve 0 si el contador está desactivado en la configuración.
  Future<int> readCounter();
}
