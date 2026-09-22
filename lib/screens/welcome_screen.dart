// Pantalla de bienvenida: espera la etiqueta y la identifica al acercarla.

import 'package:flutter/material.dart';

import '../chips/chip_catalog.dart';
import '../chips/chip_source.dart';
import '../state/tag_controller.dart';
import '../widgets/error_card.dart';
import '../widgets/update_banner.dart';
import 'chip_picker_screen.dart';
import 'workspace_screen.dart';

/// Primera pantalla: escucha la etiqueta desde el primer momento.
///
/// Si se acerca una etiqueta reconocida, la identifica, lee su ficha y entra
/// directo a trabajar. Si no la reconoce, ofrece elegir el modelo a mano.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.controller});

  /// Estado de la etiqueta, compartido con el resto de pantallas.
  final TagController controller;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with WidgetsBindingObserver {
  TagController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  /// Vuelve a buscar al recuperar el primer plano, que es cuando el usuario
  /// llega de tocar el NFC en los ajustes.
  ///
  /// La espera anterior se corta: sigue en pie aunque el NFC se haya apagado
  /// entre medias.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // La pantalla de trabajo se monta encima sin desmontar esta.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _controller.cancel();
    _controller.dismissError();
    _scan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  /// Queda a la espera de una etiqueta y la identifica al aparecer.
  Future<void> _scan() async {
    if (_controller.busy) return;
    _controller.chooseModel(null);
    await _controller.inspectTag();
    if (!mounted || _controller.chip == null) return;
    await _openWorkspace();
  }

  /// Deja elegir el modelo a mano y entra a trabajar con él.
  Future<void> _pickModel() async {
    _controller.cancel();
    final entry = await Navigator.push<ChipEntry>(
      context,
      MaterialPageRoute<ChipEntry>(
        builder: (context) => const ChipPickerScreen(),
      ),
    );
    if (entry == null || !mounted) return;
    _controller.chooseModel(entry);
    await _openWorkspace();
  }

  /// Abre la pantalla de trabajo y, al volver, se pone a buscar otra vez.
  Future<void> _openWorkspace() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => WorkspaceScreen(controller: _controller),
      ),
    );
    if (mounted) await _scan();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _controller.error;
    final chip = _controller.chip;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const UpdateBanner(),
              const SizedBox(height: 32),
              Icon(Icons.nfc, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'SUS NFC Tag Editor',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              _ScanCard(
                busy: _controller.busy,
                chip: chip?.name,
                source: chip?.source,
              ),
              const SizedBox(height: 16),
              if (error != null) ...[
                ErrorCard(
                  error: error,
                  report: _controller.errorReport(),
                  onDismiss: _controller.dismissError,
                ),
                const SizedBox(height: 16),
              ],
              OutlinedButton.icon(
                onPressed: _pickModel,
                icon: const Icon(Icons.list_alt),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Elegir el modelo a mano'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _controller.busy ? null : _scan,
                icon: const Icon(Icons.refresh),
                label: const Text('Volver a buscar'),
              ),
              const SizedBox(height: 16),
              Text(
                'Si la etiqueta no dice qué modelo es, elígelo a mano: con los '
                'clones pasa a menudo.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta que cuenta en qué punto va la detección.
class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.busy, this.chip, this.source});

  /// Indica si hay una espera de etiqueta en curso.
  final bool busy;

  /// Modelo detectado, o null si todavía no hay etiqueta.
  final String? chip;

  /// De dónde sale el modelo: de la propia etiqueta o de la elección a mano.
  final ChipSource? source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (busy)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(
                chip == null ? Icons.contactless : Icons.check_circle,
                size: 28,
                color: chip == null ? null : theme.colorScheme.primary,
              ),
            const SizedBox(height: 12),
            Text(
              switch ((busy, chip)) {
                (true, _) => 'Acerca la etiqueta al teléfono',
                (false, final String name) => '$name detectado',
                _ => 'Sin etiqueta',
              },
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
