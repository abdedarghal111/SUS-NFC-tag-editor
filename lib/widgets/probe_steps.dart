// Los tres pasos de la prueba de la contraseña, según van ocurriendo.

import 'package:flutter/material.dart';

import '../chips/results/probe_progress.dart';

/// Lista de los pasos de la prueba con el estado de cada uno.
class ProbeSteps extends StatelessWidget {
  const ProbeSteps({super.key, required this.progress});

  /// Estado en el que está cada paso ahora mismo.
  final ProbeProgress progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final step in progress.steps) _StepRow(step: step)],
        ),
      ),
    );
  }
}

/// Una línea de la lista: el estado, lo que hace el paso y lo que contestó.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  /// Paso que se pinta.
  final ProbeStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final note = step.note;
    final waiting = step.state == ProbeStepState.pending;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, height: 24, child: _mark(scheme)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: waiting ? scheme.outline : null,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Marca de la izquierda: giratoria mientras habla con la etiqueta.
  Widget _mark(ColorScheme scheme) => switch (step.state) {
    ProbeStepState.pending => Icon(
      Icons.radio_button_unchecked,
      size: 20,
      color: scheme.outlineVariant,
    ),
    ProbeStepState.running => const Padding(
      padding: EdgeInsets.all(2),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    ProbeStepState.done => Icon(
      Icons.check_circle,
      size: 20,
      color: scheme.primary,
    ),
    ProbeStepState.failed => Icon(Icons.cancel, size: 20, color: scheme.error),
  };
}
