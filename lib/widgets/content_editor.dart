// Editor de las secciones de contenido que se van a grabar.

import 'package:flutter/material.dart';

import '../chips/ndef/ndef_payload.dart';
import '../chips/ndef/ndef_record_kind.dart';
import '../utils/icons.dart';

/// Monta las secciones del mensaje NDEF y las publica según se escriben.
///
/// Entrada: el contenido con el que arranca. Salida: cada cambio llega por
/// [onChanged] ya convertido en payloads.
class ContentEditor extends StatefulWidget {
  const ContentEditor({
    super.key,
    required this.initial,
    required this.enabled,
    required this.onChanged,
  });

  /// Contenido con el que se pintan las secciones al abrir el editor.
  final List<NdefPayload> initial;

  final bool enabled;

  final ValueChanged<List<NdefPayload>> onChanged;

  @override
  State<ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<ContentEditor> {
  late final List<_Section> _sections = widget.initial.isEmpty
      ? [_Section(NdefRecordKind.link)]
      : widget.initial
            .map((payload) => _Section(payload.kind, payload.value))
            .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  @override
  void dispose() {
    for (final section in _sections) {
      section.field.dispose();
    }
    super.dispose();
  }

  /// Payloads de las secciones con texto; las vacías no se graban.
  List<NdefPayload> get _payloads => _sections
      .where((section) => section.field.text.trim().isNotEmpty)
      .map((section) => section.kind.build(section.field.text.trim()))
      .toList();

  void _publish() {
    if (!mounted) return;
    widget.onChanged(_payloads);
  }

  void _refresh() {
    setState(() {});
    _publish();
  }

  void _add(NdefRecordKind kind) {
    _sections.add(_Section(kind));
    _refresh();
  }

  void _remove(int index) {
    _sections.removeAt(index).field.dispose();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _sections.length; i++)
          _SectionField(
            section: _sections[i],
            enabled: widget.enabled,
            onKindChanged: (kind) {
              _sections[i].kind = kind;
              _refresh();
            },
            onChanged: _refresh,
            onRemove: _sections.length == 1 ? null : () => _remove(i),
          ),
        MenuAnchor(
          builder: (context, menu, child) => TextButton.icon(
            onPressed: widget.enabled
                ? () => menu.isOpen ? menu.close() : menu.open()
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Añadir sección'),
          ),
          menuChildren: [
            for (final kind in NdefRecordKind.writable)
              MenuItemButton(
                leadingIcon: Icon(iconForKind(kind)),
                onPressed: () => _add(kind),
                child: Text(kind.label),
              ),
          ],
        ),
      ],
    );
  }
}

/// Sección en edición: la clase de contenido elegida y su texto.
class _Section {
  _Section(this.kind, [String text = ''])
    : field = TextEditingController(text: text);

  /// Clase de contenido NDEF elegida para esta sección.
  NdefRecordKind kind;

  /// Texto que teclea el usuario, sin convertir todavía a payload.
  final TextEditingController field;
}

/// Campo de una sección, con su clase de contenido delante.
class _SectionField extends StatelessWidget {
  const _SectionField({
    required this.section,
    required this.enabled,
    required this.onKindChanged,
    required this.onChanged,
    this.onRemove,
  });

  final _Section section;
  final bool enabled;
  final ValueChanged<NdefRecordKind> onKindChanged;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: MenuAnchor(
              builder: (context, menu, child) => IconButton.filledTonal(
                onPressed: enabled
                    ? () => menu.isOpen ? menu.close() : menu.open()
                    : null,
                icon: Icon(iconForKind(section.kind)),
                tooltip: section.kind.label,
              ),
              menuChildren: [
                for (final kind in NdefRecordKind.writable)
                  MenuItemButton(
                    leadingIcon: Icon(iconForKind(kind)),
                    onPressed: () => onKindChanged(kind),
                    child: Text(kind.label),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: section.field,
              enabled: enabled,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: section.kind.label,
                hintText: section.kind.hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close),
              tooltip: 'Quitar',
            ),
        ],
      ),
    );
  }
}
