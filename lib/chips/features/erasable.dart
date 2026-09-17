// Capacidad de vaciar la etiqueta dejándola utilizable.

import '../results/write_report.dart';

/// Borra el contenido dejando un formato NDEF válido y vacío.
abstract interface class Erasable {
  /// Deja la etiqueta vacía pero con formato NDEF válido.
  Future<WriteReport> eraseContent({List<int> password});
}
