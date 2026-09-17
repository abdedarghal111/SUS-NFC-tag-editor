// Aplicación de Android que debe abrirse al leer la etiqueta.

import 'dart:convert';

import '../ndef_payload.dart';
import '../ndef_record_kind.dart';

/// Paquete de una app de Android, que el sistema abre o busca en la tienda.
class AndroidAppPayload extends NdefPayload {
  const AndroidAppPayload(super.value);

  @override
  NdefRecordKind get kind => NdefRecordKind.androidApp;

  @override
  EncodedRecord encode() => EncodedRecord(
    0x04,
    utf8.encode('android.com:pkg'),
    utf8.encode(value.trim()),
  );
}
