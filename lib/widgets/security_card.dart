// Detalle de cómo está protegida la etiqueta.

import 'package:flutter/material.dart';

import '../chips/results/security_status.dart';
import '../chips/results/tag_reading.dart';
import 'reading_list.dart';

/// Estado de la protección leído de las páginas de configuración.
class SecurityCard extends StatelessWidget {
  const SecurityCard({
    super.key,
    required this.security,
    this.readings = const [],
  });

  /// Protección leída de la etiqueta, ya interpretada.
  final SecurityStatus security;

  /// Bytes de configuración con su traducción, tal y como los aporta el chip.
  final List<TagReading> readings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final limit = security.failedAttemptsLimit;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado de la contraseña', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(security.scope, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (security.isLocked)
              _Line(
                icon: security.protectsReading
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                text: security.protectsReading
                    ? 'Sin la contraseña no se puede ni leer lo que tiene.'
                    : 'Leerla puede cualquiera; la contraseña solo frena los '
                          'cambios.',
              ),
            // El bit se queda escrito aunque se quite la contraseña, y es una
            // sorpresa desagradable al poner la siguiente.
            if (!security.isLocked && security.readProtectionArmed)
              _Line(
                icon: Icons.visibility_off_outlined,
                text:
                    'Ahora mismo no protege nada, pero queda puesto que la '
                    'próxima contraseña tapará también la lectura.',
              ),
            if (security.isLocked)
              _Line(
                icon: Icons.repeat,
                text: limit == 0
                    ? 'Intentos ilimitados de contraseña.'
                    : 'Tras $limit fallos la etiqueta se bloquea para '
                          'siempre.',
              ),
            if (security.passwordChecked)
              _Line(
                icon: security.passwordCorrect
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                tone: security.passwordCorrect ? null : scheme.error,
                text: security.passwordCorrect
                    ? 'La contraseña escrita es la correcta.'
                    : 'La contraseña escrita no es la de la etiqueta.',
              ),
            if (security.leaksPassword)
              _Line(
                icon: Icons.warning_amber,
                tone: scheme.error,
                text:
                    'La etiqueta deja leer su propia contraseña, así que la '
                    'protección no sirve de nada.',
              ),
            const SizedBox(height: 8),
            _TechnicalDetail(readings: readings),
          ],
        ),
      ),
    );
  }
}

/// Volcado de los bytes de configuración, guardado tras un desplegable.
class _TechnicalDetail extends StatelessWidget {
  const _TechnicalDetail({required this.readings});

  final List<TagReading> readings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text('Detalle técnico', style: theme.textTheme.bodySmall),
        children: [ReadingList(readings: readings)],
      ),
    );
  }
}

/// Renglón del detalle: un icono y su frase.
class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.tone});

  final IconData icon;
  final String text;

  /// Color con el que se resalta el renglón; null lo deja en el del tema.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: tone),
            ),
          ),
        ],
      ),
    );
  }
}
