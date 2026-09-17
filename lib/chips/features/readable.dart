// Capacidad de entregar el contenido grabado en la etiqueta.

import '../results/tag_content.dart';

/// Lee el mensaje NDEF de la etiqueta.
abstract interface class Readable {
  /// Lee el contenido, autenticando antes si la zona está protegida.
  ///
  /// La contraseña vacía significa no autenticar.
  Future<TagContent> readContent({List<int> password});
}
