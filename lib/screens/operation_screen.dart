// Pantalla de una sola operación, de principio a fin.

import 'package:flutter/material.dart';

import '../chips/ndef/ndef_payload.dart';
import '../state/tag_controller.dart';
import '../widgets/content_editor.dart';
import '../widgets/error_card.dart';
import '../widgets/password_field.dart';
import '../widgets/tag_status_strip.dart';
import 'tag_operations.dart';

/// Ejecuta una sola operación de principio a fin.
///
/// Entrada: la operación elegida. Salida: true si la etiqueta ha cambiado y la
/// ficha se ha quedado vieja.
class OperationScreen extends StatefulWidget {
  const OperationScreen({
    super.key,
    required this.controller,
    required this.operation,
  });

  /// Estado de la etiqueta sobre el que se ejecuta la operación.
  final TagController controller;

  /// Operación que esta pantalla prepara y lanza.
  final TagOperation operation;

  @override
  State<OperationScreen> createState() => _OperationScreenState();
}

class _OperationScreenState extends State<OperationScreen> {
  TagController get _c => widget.controller;

  TagOperation get _operation => widget.operation;

  /// Las operaciones que no la necesitan arrancan con el campo vacío: si
  /// viniera relleno se mandaría igual, y un fallo cuenta para el AUTHLIM.
  late final TextEditingController _password = TextEditingController(
    text: _operation.passwordOptional ? '' : _c.password,
  );

  /// Contenido montado en el editor, aún sin grabar.
  List<NdefPayload> _payloads = const [];

  /// Indica si la operación ya se ha lanzado al menos una vez.
  bool _ran = false;

  /// Estado de la casilla que ofrezca la operación.
  bool _option = false;

  @override
  void initState() {
    super.initState();
    // Descartar el error avisa a las pantallas de debajo, que en este punto
    // se están pintando todavía.
    WidgetsBinding.instance.addPostFrameCallback((_) => _c.dismissError());
    if (_operation.startsOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startIfIdle());
    }
  }

  /// Lanza la operación nada más abrirse la pantalla, si no falta nada.
  void _startIfIdle() {
    if (_c.busy || !_ready) return;
    _run();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  int get _passwordLength => _c.capabilities.password?.length ?? 4;

  /// Indica si ya está todo lo que la operación necesita para lanzarse.
  bool get _ready {
    if (_operation.needsPassword &&
        !_operation.passwordOptional &&
        _password.text.length != _passwordLength) {
      return false;
    }
    if (_operation.needsContent && _payloads.isEmpty) return false;
    return true;
  }

  /// Ejecuta la operación con la contraseña y el contenido rellenados.
  Future<void> _run() async {
    if (_operation.needsPassword) {
      _c.password = _password.text;
    }
    setState(() => _ran = true);
    await _operation.run(
      _c,
      OperationInput(
        // A medio escribir no se manda: la etiqueta la rechazaría y, con
        // AUTHLIM puesto, ese fallo cuenta.
        password:
            _operation.needsPassword && _password.text.length == _passwordLength
            ? _password.text.codeUnits
            : const [],
        payloads: _payloads,
        option: _option,
      ),
    );
  }

  /// Sale de la operación soltando la espera de la etiqueta.
  void _close() {
    _c.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final error = _c.error;
        final busy = _c.busy;
        final succeeded = _ran && !busy && error == null;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _close();
          },
          child: Scaffold(
            appBar: AppBar(title: Text(_operation.title)),
            body: ListView(
              // Hueco para los botones del sistema, que van por encima.
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                TagStatusStrip(
                  phase: _c.phase,
                  action: _c.action,
                  message: _c.lastMessage,
                  onCancel: _c.cancel,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    _operation.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_operation.warning != null)
                  _Warning(text: _operation.warning!),

                // Lo que hay que rellenar antes de acercar la etiqueta.
                if (_operation.needsContent)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: ContentEditor(
                      initial: _c.content?.payloads ?? const [],
                      enabled: !busy,
                      onChanged: (payloads) =>
                          setState(() => _payloads = payloads),
                    ),
                  ),
                if (_operation.needsPassword)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: PasswordField(
                      field: _password,
                      length: _passwordLength,
                      optional: _operation.passwordOptional,
                      enabled: !busy,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                if (_operation.optionLabel != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                    child: SwitchListTile(
                      value: _option,
                      onChanged: busy
                          ? null
                          : (value) => setState(() => _option = value),
                      title: Text(_operation.optionLabel!),
                      subtitle: _operation.optionHint == null
                          ? null
                          : Text(_operation.optionHint!),
                    ),
                  ),
                // Por dónde va, mientras la etiqueta contesta.
                if (_ran && _operation.progress != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _operation.progress!(_c),
                  ),

                // Cómo ha terminado.
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: ErrorCard(
                      error: error,
                      report: _c.errorReport(),
                      onDismiss: _c.dismissError,
                    ),
                  ),
                if (succeeded) ...[
                  _Success(message: _c.lastMessage ?? 'Operación completada.'),
                  if (_operation.detail != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _operation.detail!(_c),
                    ),
                ],

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: FilledButton.icon(
                    onPressed: busy || !_ready ? null : _run,
                    icon: Icon(_ran ? Icons.refresh : _operation.icon),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(switch ((_ran, error != null)) {
                        (false, _) => 'Acercar la etiqueta',
                        (true, true) => 'Reintentar',
                        (true, false) => 'Repetir',
                      }),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: TextButton(
                    onPressed: _close,
                    child: const Text('Volver a la etiqueta'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Aviso previo de las operaciones que no tienen vuelta atrás.
class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              size: 20,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmación de que la etiqueta ha aceptado la operación.
class _Success extends StatelessWidget {
  const _Success({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
