// Lecturas que la etiqueta lleva contadas de fábrica.

import 'tag_result.dart';

/// Veces que la etiqueta dice que se ha leído.
class CounterResult extends TagResult {
  const CounterResult(this.reads);

  /// Valor del contador; 0 si está desactivado.
  final int reads;

  @override
  String get summary => reads == 0
      ? 'El contador está a cero o desactivado.'
      : 'La etiqueta se ha leído $reads veces.';
}
