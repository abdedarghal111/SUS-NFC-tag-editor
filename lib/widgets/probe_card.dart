// Veredicto de la prueba de protección.

import 'package:flutter/material.dart';

import '../chips/results/protection_probe.dart';
import '../utils/hex.dart';
import 'verdict_card.dart';

/// Resultado de poner una contraseña e intentar escribir sin ella para ver si
/// la etiqueta lo rechaza de verdad.
class ProbeCard extends StatelessWidget {
  const ProbeCard({super.key, required this.probe});

  /// Resultado de la prueba, con el veredicto y los bytes en que se apoya.
  final ProtectionProbe probe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = probe.warning;

    return VerdictCard(
      passed: probe.passed,
      icon: Icons.verified_user,
      failedIcon: Icons.gpp_maybe,
      verdict: probe.verdict,
      children: [
        const SizedBox(height: 8),
        Text(probe.detail, style: theme.textTheme.bodyMedium),
        if (warning != null) ...[
          const SizedBox(height: 8),
          Text(
            warning,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SelectableText(
          'CFG0 ${hexBytes(probe.config)} · AUTH0 ${hexByte(probe.auth0)}',
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
