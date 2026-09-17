// Recuento de lo grabado en la etiqueta.

import 'tag_result.dart';

/// Recuento de lo grabado en la etiqueta.
class WriteReport extends TagResult {
  const WriteReport({required this.bytesWritten, required this.pagesWritten});

  /// Bytes efectivamente escritos, relleno incluido.
  final int bytesWritten;

  /// Páginas de 4 bytes que se han escrito.
  final int pagesWritten;

  @override
  String get summary =>
      'Grabados $bytesWritten bytes en $pagesWritten páginas.';
}
