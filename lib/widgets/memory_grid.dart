// Rejilla con el estado de cada página durante la prueba de la memoria.

import 'package:flutter/material.dart';

import '../chips/results/memory_test.dart';

/// Una casilla por página, con el color de cómo ha respondido.
class MemoryGrid extends StatelessWidget {
  const MemoryGrid({super.key, required this.progress});

  /// Estado de las páginas y fase en la que va la prueba.
  final MemoryProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = progress.blocks;
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.phase.label,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${progress.goodCount} bien · ${progress.badCount} mal · '
                  '${blocks.length} páginas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (var i = 0; i < blocks.length; i++)
                  _Block(state: blocks[i], page: progress.firstPage + i),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Casilla de una página: gris mientras espera, verde o roja al contestar.
class _Block extends StatelessWidget {
  const _Block({required this.state, required this.page});

  final MemoryBlockState state;

  /// Página de la etiqueta que representa, para el mensaje al tocarla.
  final int page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Las que no se tocan van a rayas: se ven distintas de un vistazo y no
    // gastan ninguno de los colores que dicen cómo ha respondido la etiqueta.
    if (state == MemoryBlockState.skipped) {
      return Tooltip(
        message: 'Página $page: cabecera, bloqueo o configuración; no se toca',
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              tileMode: TileMode.repeated,
              stops: const [0, 0.5, 0.5, 1],
              colors: [
                scheme.surfaceContainerHighest,
                scheme.surfaceContainerHighest,
                scheme.outlineVariant,
                scheme.outlineVariant,
              ],
              transform: const GradientRotation(0.8),
            ),
          ),
        ),
      );
    }

    final color = switch (state) {
      MemoryBlockState.pending => scheme.surfaceContainerHighest,
      MemoryBlockState.busy => scheme.primary.withValues(alpha: 0.45),
      MemoryBlockState.good => Colors.green.shade600,
      MemoryBlockState.bad => scheme.error,
      MemoryBlockState.skipped => scheme.outlineVariant,
    };

    return Tooltip(
      message: 'Página $page',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
