// Base de lo que devuelve una operación sobre la etiqueta.

/// Respuesta ya interpretada: la interfaz no tiene que saber de bytes.
abstract class TagResult {
  const TagResult();

  /// Frase corta que resume lo que ha contestado la etiqueta.
  String get summary;
}
