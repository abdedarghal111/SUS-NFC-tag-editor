// Veredicto de la medición de la memoria.

import 'package:flutter/material.dart';

import '../chips/results/capacity_probe.dart';
import 'verdict_card.dart';

/// Resultado de escribir en todas las páginas para ver cuánta memoria hay.
class CapacityCard extends StatelessWidget {
  const CapacityCard({super.key, required this.capacity});

  /// Medición de la que se rinde cuentas: bytes declarados y bytes reales.
  final CapacityProbe capacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final complete = capacity.isComplete;
    final declared = capacity.declaredBytes;
    final share = declared > 0
        ? (capacity.measuredBytes / declared).clamp(0.0, 1.0)
        : 1.0;

    return VerdictCard(
      passed: complete,
      icon: Icons.sd_storage,
      failedIcon: Icons.report_gmailerrorred,
      verdict: capacity.verdict,
      children: [
        if (declared > 0) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Memoria real sobre la declarada',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Text(
                '${capacity.measuredBytes} / $declared B',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 8,
              color: complete ? null : scheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'La etiqueta se ha quedado vacía: la prueba escribe encima de todo '
          'el contenido.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
