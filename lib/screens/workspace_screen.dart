// Panel de la etiqueta: lo que se sabe de ella y lo que se le puede pedir.

import 'package:flutter/material.dart';

import '../nfc/nfc_reader.dart';
import '../state/tag_controller.dart';
import '../widgets/error_card.dart';
import '../widgets/operation_tile.dart';
import '../widgets/tag_card.dart';
import '../widgets/tag_status_strip.dart';
import 'operation_screen.dart';
import 'tag_operations.dart';

/// Panel de la etiqueta: arriba todo lo que se sabe de ella, abajo las
/// operaciones repartidas por apartados.
///
/// Cada operación se ejecuta en su propia pantalla; aquí solo se elige.
class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, required this.controller});

  /// Estado de la etiqueta, compartido con el resto de pantallas.
  final TagController controller;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with WidgetsBindingObserver {
  TagController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _readIfIdle());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // El lector se suelta en segundo plano para no bloquear el NFC del sistema.
    if (state == AppLifecycleState.resumed) {
      _c.start();
    } else if (state == AppLifecycleState.paused) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Lee la ficha al abrir la pantalla, si no se ha leído ya.
  void _readIfIdle() {
    if (_c.busy || _c.info != null) return;
    _c.inspectTag();
  }

  /// Abre la operación en su pantalla; la ficha la deja al día la propia
  /// operación, sin volver a pedir la etiqueta.
  Future<void> _open(TagOperation operation) => Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (context) =>
          OperationScreen(controller: _c, operation: operation),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final chip = _c.chip;
        final error = _c.error;
        final model = _c.modelName ?? 'Etiqueta';
        final operations = operationsFor(_c);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(model),
                actions: [
                  IconButton(
                    onPressed: _c.busy ? null : _c.inspectTag,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Volver a leer la ficha',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Cambiar de etiqueta o de modelo',
                  ),
                ],
              ),
              SliverList.list(
                children: [
                  // En reposo la tira no cuenta nada que no diga ya la ficha.
                  if (_c.phase != NfcPhase.idle)
                    TagStatusStrip(
                      phase: _c.phase,
                      action: _c.action,
                      message: _c.lastMessage,
                      onCancel: _c.cancel,
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: ErrorCard(
                        error: error,
                        report: _c.errorReport(),
                        onDismiss: _c.dismissError,
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TagCard(
                      model: model,
                      info: _c.info,
                      capabilities: _c.capabilities,
                      source: chip?.source ?? _c.sourceOfChoice,
                      tested: _c.tested,
                      readings: _c.readings,
                      content: _c.content,
                      counter: _c.counter,
                    ),
                  ),

                  // Lo que se puede hacer con ella, apartado por apartado.
                  for (final group in OperationGroup.values) ...[
                    if (operations.any((operation) => operation.group == group))
                      _SectionTitle(group: group),
                    for (final operation in operations.where(
                      (operation) => operation.group == group,
                    ))
                      OperationTile(
                        icon: operation.icon,
                        title: operation.title,
                        subtitle: operation.subtitle,
                        busy: _c.busy,
                        danger: operation.danger,
                        onTap: () => _open(operation),
                      ),
                  ],

                  // Hueco para los botones del sistema, que van por encima.
                  SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Título de un apartado de operaciones.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.group});

  /// Apartado que encabeza.
  final OperationGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: group.danger
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.danger) ...[
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  group.hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: group.danger ? theme.colorScheme.error : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
