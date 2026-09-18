// Veredicto de la prueba de protección.

import 'package:flutter/material.dart';

import '../chips/results/protection_probe.dart';
import '../utils/hex.dart';
import 'verdict_card.dart';

/// Resultado de intentar escribir sin contraseña para ver si la etiqueta lo
/// rechaza de verdad.
class ProbeCard extends StatelessWidget {
  const ProbeCard({super.key, required this.probe});

  /// Resultado de la prueba, con el veredicto y los bytes en que se apoya.
  final ProtectionProbe probe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VerdictCard(
      passed: probe.isConsistent,
      icon: Icons.verified_user,
      failedIcon: Icons.gpp_maybe,
      verdict: probe.verdict,
      children: [
        const SizedBox(height: 12),
        SelectableText(
          'CFG0 ${hexBytes(probe.config)} · AUTH0 '
          '${hexByte(probe.auth0)} · AUTH0 en '
          '${probe.layout.label.toLowerCase()}',
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
