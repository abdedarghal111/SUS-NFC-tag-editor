// Pantalla para elegir el modelo a mano cuando la etiqueta no lo declara.

import 'package:flutter/material.dart';

import '../chips/chip_catalog.dart';

/// Catálogo de modelos agrupado por familia.
///
/// Devuelve la [ChipEntry] elegida, o null si se sale sin elegir. Los modelos
/// que la app no sabe manejar se enseñan apagados.
class ChipPickerScreen extends StatelessWidget {
  const ChipPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir modelo')),
      body: ListView(
        children: [
          for (final family in ChipCatalog.families) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                family.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            for (final entry in ChipCatalog.ofFamily(family))
              _ModelTile(entry: entry),
          ],
          // Hueco para los botones del sistema, que van por encima.
          SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

/// Fila de un modelo, con su estado de soporte.
class _ModelTile extends StatelessWidget {
  const _ModelTile({required this.entry});

  /// Modelo que representa la fila.
  final ChipEntry entry;

  @override
  Widget build(BuildContext context) {
    final capacity = entry.capabilities.maxContentBytes;
    return ListTile(
      enabled: entry.enabled,
      leading: Icon(
        entry.enabled ? Icons.memory : Icons.block,
        color: entry.enabled ? null : Theme.of(context).disabledColor,
      ),
      title: Text(entry.name),
      subtitle: Text(
        entry.enabled
            ? [
                if (capacity > 0) '$capacity B',
                if (entry.devTested) 'probado' else 'sin probar',
              ].join(' · ')
            : 'Sin implementar',
      ),
      trailing: entry.devTested ? const Icon(Icons.verified, size: 18) : null,
      onTap: entry.enabled ? () => Navigator.pop(context, entry) : null,
    );
  }
}
