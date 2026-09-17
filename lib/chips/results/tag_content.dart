// Contenido NDEF leído de la etiqueta.

import '../../ndef/ndef_payload.dart';
import 'tag_result.dart';

/// Contenido NDEF grabado en la etiqueta.
class TagContent extends TagResult {
  const TagContent({required this.payloads, required this.usedBytes});

  final List<NdefPayload> payloads;

  final int usedBytes;

  bool get isEmpty => payloads.isEmpty;

  @override
  String get summary => isEmpty
      ? 'La etiqueta está vacía.'
      : '${payloads.length} sección(es) leídas, $usedBytes bytes.';
}
