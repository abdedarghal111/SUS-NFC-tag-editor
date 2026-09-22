// Un dato que la etiqueta cuenta de sí misma, con su lectura en claro.

/// Dato en crudo acompañado de lo que significa.
///
/// Cada familia de chips compone los suyos: el nivel de abajo aporta lo que
/// vale para cualquier etiqueta y los de arriba añaden lo suyo.
class TagReading {
  const TagReading({
    required this.label,
    required this.raw,
    this.notes = const [],
  });

  /// Nombre del dato tal y como se conoce en la documentación.
  final String label;

  /// El valor en crudo, en hexadecimal.
  final String raw;

  /// Qué significa, una frase por cosa que diga.
  final List<String> notes;
}
