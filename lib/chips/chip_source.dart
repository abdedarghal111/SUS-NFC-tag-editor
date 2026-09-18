// De dónde sale el modelo que se le atribuye a la etiqueta.

/// Cómo se ha averiguado el modelo del chip.
enum ChipSource {
  /// La etiqueta lo ha declarado en GET_VERSION y se reconoce.
  declared,

  /// Se ha comprobado midiendo la memoria, no solo preguntando.
  measured,

  /// Lo ha elegido el usuario a mano, sin que la etiqueta lo confirme.
  chosen,
}
