// Presentación de los errores de NFC en la pantalla principal.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chips/errors/nfc_error.dart';
import '../chips/errors/nfc_unavailable_error.dart';
import '../nfc/nfc_settings.dart';

/// Aviso de error persistente: se queda hasta que se cierra a mano y permite
/// copiar el detalle técnico completo.
class ErrorCard extends StatefulWidget {
  const ErrorCard({
    super.key,
    required this.error,
    required this.report,
    required this.onDismiss,
  });

  /// Error que se muestra; su tipo decide qué botón de acción se ofrece.
  final NfcError error;

  /// Detalle técnico completo, el que se copia al portapapeles.
  final String report;

  final VoidCallback onDismiss;

  @override
  State<ErrorCard> createState() => _ErrorCardState();
}

class _ErrorCardState extends State<ErrorCard> {
  bool _showDetails = false;

  /// Indica si el error se arregla activando el NFC en los ajustes.
  bool get _canEnableNfc {
    final error = widget.error;
    return error is NfcUnavailableError && error.canBeEnabled;
  }

  /// Abre los ajustes de NFC del sistema y avisa si no se pueden abrir.
  Future<void> _openNfcSettings() async {
    if (await NfcSettings.open()) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se han podido abrir los ajustes de NFC'),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.report));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.error.message,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: widget.onDismiss,
                icon: Icon(Icons.close, color: scheme.onErrorContainer),
              ),
            ],
          ),
          if (_showDetails)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText(
                  widget.report,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _showDetails = !_showDetails),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                ),
                child: Text(_showDetails ? 'Ocultar detalle' : 'Ver detalle'),
              ),
              if (_canEnableNfc)
                FilledButton.icon(
                  onPressed: _openNfcSettings,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Activar NFC'),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_all, size: 18),
                  label: const Text('Copiar error'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
