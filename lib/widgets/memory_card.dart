// Veredicto de la prueba de la memoria.

import 'package:flutter/material.dart';

import '../chips/results/memory_test.dart';
import 'verdict_card.dart';

/// Resultado de escribir, releer y borrar la memoria de la etiqueta.
class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.test});

  /// Recuento de las tres fases, ya con su veredicto.
  final MemoryTest test;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VerdictCard(
      passed: test.passed,
      icon: Icons.verified,
      failedIcon: Icons.gpp_maybe,
      verdict: test.verdict,
      children: [
        const SizedBox(height: 8),
        Text(test.detail, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        _Phase(
          label: 'Escritas',
          done: test.writtenPages,
          total: test.totalPages,
        ),
        _Phase(
          label: 'Releídas',
          done: test.verifiedPages,
          total: test.totalPages,
        ),
        _Phase(
          label: 'Borradas',
          done: test.erasedPages,
          total: test.totalPages,
        ),
        const SizedBox(height: 8),
        Text(
          'La etiqueta declara ${test.declaredBytes} B',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Recuento de una fase: páginas logradas sobre el total, y sus bytes.
class _Phase extends StatelessWidget {
  const _Phase({required this.label, required this.done, required this.total});

  /// Nombre de la fase.
  final String label;

  /// Páginas que salieron bien.
  final int done;

  /// Páginas que se intentaron.
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final complete = done == total;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: complete ? Colors.green.shade700 : scheme.error,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$done de $total páginas · ${done * 4} B',
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
