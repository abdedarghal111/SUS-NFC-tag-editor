// Posición del byte AUTH0 dentro de la página de configuración.

/// Posición de AUTH0 dentro de CFG0.
///
/// El estándar lo pone en el último byte, pero algunos clones no lo respetan.
/// Poder elegir permite averiguar cuál honra el chip que se tenga delante.
enum Auth0Layout {
  /// Posición del estándar: AUTH0 es el último byte de CFG0, el byte 3.
  standard(3, 'Último byte'),

  /// Posición de los clones que colocan AUTH0 en el byte 0 de CFG0.
  firstByte(0, 'Primer byte');

  const Auth0Layout(this.offset, this.label);

  /// Índice del byte de AUTH0 dentro de CFG0.
  final int offset;

  /// Nombre de la posición tal y como se muestra en la interfaz.
  final String label;
}
