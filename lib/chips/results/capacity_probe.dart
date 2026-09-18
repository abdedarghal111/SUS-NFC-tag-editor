// Memoria que la etiqueta tiene de verdad, frente a la que declara.

import 'tag_result.dart';

/// Resultado de medir la memoria escribiendo en todas las páginas.
///
/// Un clon puede declarar más memoria de la que lleva y repetir la que tiene;
/// escribir página a página es lo único que lo descubre.
class CapacityProbe extends TagResult {
  const CapacityProbe({
    required this.declaredBytes,
    required this.measuredBytes,
    required this.lastGoodPage,
    required this.wrapped,
    required this.rejected,
  });

  /// Bytes que la etiqueta declara en el CC de la página 3.
  final int declaredBytes;

  /// Bytes en los que se ha podido escribir sin que se repitan.
  final int measuredBytes;

  /// Última página que ha guardado lo suyo.
  final int lastGoodPage;

  /// La etiqueta ha vuelto al principio: la memoria de más no existe.
  final bool wrapped;

  /// La etiqueta ha rechazado seguir escribiendo.
  final bool rejected;

  /// La memoria ha aguantado toda la zona de contenido que se puede probar.
  bool get isComplete => !wrapped && !rejected;

  /// Explica el resultado de la medición en lenguaje llano.
  String get verdict {
    if (wrapped) {
      return 'Memoria falsa: a partir de la página $lastGoodPage la etiqueta '
          'vuelve a escribir sobre el principio. Tiene $measuredBytes bytes '
          'reales y declara $declaredBytes.';
    }
    if (rejected) {
      return 'La memoria se acaba en la página $lastGoodPage: $measuredBytes '
          'bytes reales, aunque declara $declaredBytes.';
    }
    return 'Memoria real: ha guardado $measuredBytes bytes seguidos sin '
        'repetirse ni rechazar ninguna página, y declara $declaredBytes.';
  }

  @override
  String get summary => isComplete
      ? 'Memoria comprobada: $measuredBytes bytes reales.'
      : 'Solo $measuredBytes de los $declaredBytes bytes declarados son '
            'reales.';
}
