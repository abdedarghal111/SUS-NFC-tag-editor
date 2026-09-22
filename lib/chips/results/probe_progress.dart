// Estado de los pasos de la prueba de la contraseña mientras se ejecutan.

/// En qué punto está un paso de la prueba.
enum ProbeStepState {
  /// Todavía no le ha llegado el turno.
  pending,

  /// Se está hablando con la etiqueta.
  running,

  /// Ha salido como debía.
  done,

  /// No ha salido como debía.
  failed,
}

/// Un paso de la prueba, con lo que ha contestado la etiqueta.
class ProbeStep {
  const ProbeStep({required this.title, required this.state, this.note});

  /// Lo que hace el paso, en una línea.
  final String title;

  /// En qué punto está.
  final ProbeStepState state;

  /// Lo que ha contestado la etiqueta, o null si aún no ha contestado.
  final String? note;

  ProbeStep copyWith({required ProbeStepState state, String? note}) =>
      ProbeStep(title: title, state: state, note: note ?? this.note);
}

/// Los tres pasos de la prueba de la contraseña, en orden.
class ProbeProgress {
  const ProbeProgress([this.steps = _initial]);

  /// Índice del paso que pone la contraseña.
  static const int setPassword = 0;

  /// Índice del paso que intenta escribir sin la contraseña.
  static const int write = 1;

  /// Índice del paso que quita la contraseña.
  static const int removePassword = 2;

  static const List<ProbeStep> _initial = [
    ProbeStep(title: 'Poner la contraseña', state: ProbeStepState.pending),
    ProbeStep(
      title: 'Escribir sin la contraseña',
      state: ProbeStepState.pending,
    ),
    ProbeStep(title: 'Quitar la contraseña', state: ProbeStepState.pending),
  ];

  /// Los tres pasos tal y como están ahora mismo.
  final List<ProbeStep> steps;

  /// Devuelve el progreso con el paso [index] cambiado.
  ProbeProgress at(int index, ProbeStepState state, {String? note}) =>
      ProbeProgress([
        for (var i = 0; i < steps.length; i++)
          if (i == index)
            steps[i].copyWith(state: state, note: note)
          else
            steps[i],
      ]);
}
