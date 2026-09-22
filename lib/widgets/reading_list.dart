// Bytes de la etiqueta con su traducción al lado.

import 'package:flutter/material.dart';

import '../chips/results/tag_reading.dart';

/// Lista de datos en crudo, cada uno con lo que significa en la misma línea.
class ReadingList extends StatelessWidget {
  const ReadingList({super.key, required this.readings});

  /// Datos a pintar, en el orden en que los aporta el chip.
  final List<TagReading> readings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final reading in readings) _Reading(reading: reading)],
    );
  }
}

/// Un dato: su nombre, el valor en crudo y a qué se traduce.
class _Reading extends StatelessWidget {
  const _Reading({required this.reading});

  final TagReading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(reading.label, style: style)),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: reading.raw,
                    style: style?.copyWith(fontFamily: 'monospace'),
                  ),
                  if (reading.notes.isNotEmpty)
                    TextSpan(
                      text: ' — ${reading.notes.join(' · ')}',
                      style: style,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
