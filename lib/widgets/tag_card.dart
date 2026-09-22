// Ficha de la etiqueta: identidad, estado, espacio, contenido y datos técnicos.

import 'package:flutter/material.dart';

import '../chips/chip_capabilities.dart';
import '../chips/chip_source.dart';
import '../chips/results/tag_content.dart';
import '../chips/results/tag_info.dart';
import '../chips/results/tag_reading.dart';
import '../utils/hex.dart';
import '../utils/icons.dart';
import 'reading_list.dart';

/// Todo lo que se sabe de la etiqueta, en una sola ficha.
///
/// Lo que decide si la etiqueta sirve va destacado arriba; los datos técnicos
/// quedan debajo, en gris y sin repetirse.
class TagCard extends StatelessWidget {
  const TagCard({
    super.key,
    required this.model,
    required this.info,
    required this.capabilities,
    required this.source,
    required this.tested,
    this.readings = const [],
    this.content,
    this.counter,
  });

  /// Nombre del modelo con el que se está trabajando.
  final String model;

  /// Datos leídos de la etiqueta, o null mientras no haya ninguna delante.
  final TagInfo? info;

  /// Lo que el modelo admite; decide qué apartados se pintan.
  final ChipCapabilities capabilities;

  /// Cómo se supo el modelo, para avisar si lo eligió el usuario.
  final ChipSource? source;

  /// Indica si el soporte de este modelo se ha probado contra una etiqueta
  /// real; si no, la ficha lo avisa en rojo.
  final bool tested;

  /// Bytes de la ficha con su traducción, tal y como los aporta el chip.
  final List<TagReading> readings;

  /// Contenido leído, o null si todavía no se ha leído.
  final TagContent? content;

  /// Último valor leído del contador, si se ha leído.
  final int? counter;

  /// Cómo se llama en la ficha el origen del modelo.
  String get _sourceLabel => switch (source) {
    ChipSource.declared => 'declarado por la etiqueta',
    ChipSource.measured => 'medido sobre la memoria',
    ChipSource.chosen => 'elegido a mano',
    null => 'sin confirmar',
  };

  /// Capacidad real con la que se mide el espacio: la del CC si la etiqueta ya
  /// la ha contado, y si no la del modelo.
  int get _capacity {
    final declared = info?.capacityBytes ?? 0;
    return declared > 0 ? declared : capabilities.maxContentBytes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tag = info;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contactless, size: 28, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        tag == null ? 'Acerca la etiqueta' : hexBytes(tag.uid),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: tag == null ? null : 'monospace',
                        ),
                      ),
                      Text(
                        '$model · $_sourceLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!tested) ...[
              const SizedBox(height: 16),
              const _Flag(
                tone: _Tone.bad,
                icon: Icons.dangerous,
                label: 'SIN PROBAR · PELIGROSO',
              ),
              const SizedBox(height: 6),
              Text(
                'No se ha comprobado que este modelo funcione bien: podría '
                'dañar la etiqueta.',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],

            if (tag != null) ...[
              const SizedBox(height: 16),
              _Flags(info: tag, capabilities: capabilities, counter: counter),
            ],

            // Con la lectura protegida el hueco ocupado es desconocido, y una
            // barra vacía diría que está libre.
            if (_capacity > 0 && !(tag?.readProtected ?? false)) ...[
              const SizedBox(height: 20),
              _Usage(used: content?.usedBytes, capacity: _capacity),
            ],

            if (tag != null && tag.readProtected) ...[
              const SizedBox(height: 16),
              Text(
                'No cuenta lo que tiene grabado sin la contraseña. Con ella, '
                '«Leer con contraseña» trae el resto de la ficha.',
                style: theme.textTheme.bodyMedium,
              ),
            ],

            if (content != null) ...[
              const SizedBox(height: 8),
              if (content!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'La etiqueta está vacía.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                for (final payload in content!.payloads)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(iconForKind(payload.kind), size: 20),
                    title: Text(payload.kind.label),
                    subtitle: SelectableText(payload.value),
                  ),
            ],

            if (tag != null) ...[
              const Divider(height: 32),
              _Details(
                info: tag,
                capabilities: capabilities,
                model: model,
                readings: readings,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Peso que se le da a un dato destacado.
enum _Tone { good, bad, warn, plain }

/// Estado de la etiqueta en insignias de color: lo que decide si sirve.
class _Flags extends StatelessWidget {
  const _Flags({
    required this.info,
    required this.capabilities,
    required this.counter,
  });

  final TagInfo info;
  final ChipCapabilities capabilities;
  final int? counter;

  /// Insignia de autenticidad según lo que haya contestado la etiqueta.
  (_Tone, IconData, String) get _authenticity {
    if (info.manufacturer == null) {
      return (_Tone.warn, Icons.help_outline, 'Sin GET_VERSION');
    }
    if (!info.isGenuineNxp) {
      return (_Tone.warn, Icons.copy_all_outlined, 'Clon compatible');
    }
    if (!info.hasSignature) {
      return (_Tone.warn, Icons.gpp_maybe, 'NXP sin firma');
    }
    return (_Tone.good, Icons.verified, 'NXP auténtico');
  }

  @override
  Widget build(BuildContext context) {
    final authenticity = _authenticity;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (capabilities.hasSecurity)
          _Flag(
            tone: info.isLocked ? _Tone.bad : _Tone.good,
            icon: info.isLocked ? Icons.lock : Icons.lock_open,
            label: switch ((info.isLocked, info.config.isEmpty)) {
              (false, _) => 'Sin contraseña',
              // Sin CFG0 no se sabe desde qué página protege.
              (true, true) => 'Con contraseña',
              (true, false) => 'Con contraseña desde la página ${info.auth0}',
            },
          ),
        if (info.readProtected)
          const _Flag(
            tone: _Tone.bad,
            icon: Icons.visibility_off,
            label: 'Lectura protegida',
          ),
        _Flag(
          tone: authenticity.$1,
          icon: authenticity.$2,
          label: authenticity.$3,
        ),
        if (capabilities.hasCounter)
          _Flag(
            tone: _Tone.plain,
            icon: Icons.numbers_outlined,
            label: counter == null ? 'Contador sin leer' : '$counter lecturas',
          ),
      ],
    );
  }
}

/// Dato destacado, con su color según lo que signifique.
class _Flag extends StatelessWidget {
  const _Flag({required this.tone, required this.icon, required this.label});

  final _Tone tone;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (foreground, background) = switch (tone) {
      _Tone.good => (Colors.green.shade800, Colors.green.shade50),
      _Tone.bad => (scheme.onErrorContainer, scheme.errorContainer),
      _Tone.warn => (Colors.orange.shade900, Colors.orange.shade50),
      _Tone.plain => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// Espacio de contenido: lo usado sobre lo que cabe.
class _Usage extends StatelessWidget {
  const _Usage({required this.used, required this.capacity});

  /// Bytes ocupados, o null si todavía no se ha leído el contenido.
  final int? used;

  final int capacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = used ?? 0;
    final share = (bytes / capacity).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Contenido', style: theme.textTheme.titleSmall),
            ),
            Text(
              used == null
                  ? '$capacity B libres'
                  : '$bytes / $capacity B · ${(share * 100).round()} %',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: share, minHeight: 8),
        ),
      ],
    );
  }
}

/// Datos técnicos de la etiqueta, en segundo plano.
class _Details extends StatelessWidget {
  const _Details({
    required this.info,
    required this.capabilities,
    required this.model,
    required this.readings,
  });

  final TagInfo info;
  final ChipCapabilities capabilities;
  final String model;
  final List<TagReading> readings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final declared = capabilities.maxContentBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadingList(readings: readings),
        if (declared > 0 && declared != info.capacityBytes)
          _DetailRow(label: 'Capacidad de un $model', value: '$declared B'),
        const SizedBox(height: 8),
        Text(
          info.authenticity,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Fila de un dato técnico.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

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
          SizedBox(width: 120, child: Text(label, style: style)),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              value,
              style: style?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
