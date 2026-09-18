// Fila de una operación que se puede pedir a la etiqueta.

import 'package:flutter/material.dart';

/// Operación disponible, con su icono y una línea de qué hace.
class OperationTile extends StatelessWidget {
  const OperationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;

  /// Nombre corto de la operación.
  final String title;

  /// Una línea diciendo qué hace, en lenguaje llano.
  final String subtitle;

  /// Con una operación en marcha no se admite otra.
  final bool busy;

  final VoidCallback onTap;

  /// Marca las operaciones de las que no se vuelve.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : scheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          enabled: !busy,
          onTap: busy ? null : onTap,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right, size: 20),
        ),
      ),
    );
  }
}
