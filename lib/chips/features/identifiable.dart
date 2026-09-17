// Capacidad de decir qué modelo es sin tener que deducirlo.

import '../results/tag_info.dart';

/// Responde con su fabricante, modelo y memoria.
///
/// Lo que conteste es declarativo: un clon puede mentir o no contestar.
abstract interface class Identifiable {
  /// Reúne la ficha de la etiqueta: UID, capacidad, protección y versión.
  Future<TagInfo> readInfo();

  /// Comprueba contra la etiqueta que el modelo es el que dice esta clase.
  Future<bool> matchesTag();
}
