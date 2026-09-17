// De dónde sale la certeza sobre qué modelo es la etiqueta.

/// Cómo se ha averiguado el modelo del chip.
enum ChipSource {
  /// La etiqueta lo ha declarado en GET_VERSION y se reconoce.
  declared,

  /// Se ha comprobado midiendo la memoria, no solo preguntando.
  measured,

  /// La etiqueta no lo dice o dice algo desconocido: se trabaja a ciegas.
  assumed,
}
