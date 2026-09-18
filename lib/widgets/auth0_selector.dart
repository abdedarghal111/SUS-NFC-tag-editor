// Ajuste fino: dónde busca AUTH0 el chip.

import 'package:flutter/material.dart';

import '../chips/type2/auth0_layout.dart';

/// Elige en qué byte de CFG0 vive AUTH0.
///
/// Solo aparece en las operaciones que escriben o interpretan ese byte, que
/// son las únicas a las que la elección afecta.
class Auth0Selector extends StatelessWidget {
  const Auth0Selector({
    super.key,
    required this.layout,
    required this.enabled,
    required this.onChanged,
  });

  /// Byte de CFG0 en el que se da por supuesto que vive AUTH0.
  final Auth0Layout layout;

  final bool enabled;

  final ValueChanged<Auth0Layout> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.tune),
        title: const Text('Ajuste fino'),
        subtitle: const Text('Solo si la contraseña no llega a aplicarse'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            'AUTH0 dice desde qué página hace falta contraseña, y vive dentro '
            'de la página de configuración. Casi todos los chips lo ponen en '
            'el último byte; algún clon lo busca en el primero.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SegmentedButton<Auth0Layout>(
            segments: [
              for (final value in Auth0Layout.values)
                ButtonSegment(value: value, label: Text(value.label)),
            ],
            selected: {layout},
            onSelectionChanged: enabled
                ? (values) => onChanged(values.first)
                : null,
          ),
        ],
      ),
    );
  }
}
