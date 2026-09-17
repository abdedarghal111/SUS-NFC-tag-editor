// Posición del byte AUTH0 dentro de la página de configuración.

/// Posición de AUTH0 dentro de CFG0.
///
/// El estándar lo pone en el último byte, pero algunos clones no lo respetan.
/// Poder elegir permite averiguar cuál honra el chip que se tenga delante.
enum Auth0Layout {
  standard(3, 'Estándar (byte 3)'),
  firstByte(0, 'Byte 0 (clones)');

  const Auth0Layout(this.offset, this.label);

  /// Índice del byte de AUTH0 dentro de CFG0.
  final int offset;

  final String label;
}
