// Texto plano con marca de idioma.

import 'dart:convert';

import '../ndef_payload.dart';
import '../ndef_record_kind.dart';

/// Texto libre acompañado del código de idioma.
class TextPayload extends NdefPayload {
  const TextPayload(super.value, {this.language = 'es'});

  /// Código de idioma que acompaña al texto.
  final String language;

  @override
  NdefRecordKind get kind => NdefRecordKind.text;

  @override
  EncodedRecord encode() {
    final languageBytes = utf8.encode(language);
    return EncodedRecord(0x01, utf8.encode('T'), [
      // El primer byte guarda la longitud del idioma; el bit 7 a 0 marca UTF-8.
      languageBytes.length,
      ...languageBytes,
      ...utf8.encode(value),
    ]);
  }
}
