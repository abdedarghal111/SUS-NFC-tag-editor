// Dictamen de una prueba hecha contra la etiqueta, con sus datos debajo.

import 'package:flutter/material.dart';

/// Resultado de una prueba hecha contra la etiqueta.
///
/// Pone arriba el dictamen, con el icono teñido según si la etiqueta cumple lo
/// que declara, y debajo los datos en que se apoya.
class VerdictCard extends StatelessWidget {
  const VerdictCard({
    super.key,
    required this.passed,
    required this.icon,
    required this.failedIcon,
    required this.verdict,
    required this.children,
  });

  /// Indica si la etiqueta ha salido bien parada de la prueba.
  final bool passed;

  /// Icono del dictamen favorable.
  final IconData icon;

  /// Icono del dictamen desfavorable.
  final IconData failedIcon;

  /// El dictamen, en una frase.
  final String verdict;

  /// Lo que respalda el dictamen, debajo del titular.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  passed ? icon : failedIcon,
                  color: passed ? scheme.primary : scheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(verdict, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
