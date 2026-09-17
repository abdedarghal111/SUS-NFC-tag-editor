// Registro de un tipo que la app no interpreta.

import 'dart:convert';

import '../ndef_payload.dart';
import '../ndef_record_kind.dart';

/// Contenido que no encaja en ninguna clase conocida; se conserva como texto.
class UnknownPayload extends NdefPayload {
  const UnknownPayload(super.value);

  @override
  NdefRecordKind get kind => NdefRecordKind.unknown;

  @override
  EncodedRecord encode() => EncodedRecord(0x05, const [], utf8.encode(value));
}
