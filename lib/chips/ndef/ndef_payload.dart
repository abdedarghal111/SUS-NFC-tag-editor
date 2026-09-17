// Base de los contenidos que se graban como registro NDEF.

import 'ndef_record_kind.dart';

/// Registro NDEF ya codificado: los tres campos que van al mensaje.
class EncodedRecord {
  const EncodedRecord(this.tnf, this.type, this.payload);

  /// Type Name Format: 0x01 para tipos del foro NFC, 0x04 para externos.
  final int tnf;

  /// Nombre del tipo, por ejemplo `U` para URI o `T` para texto.
  final List<int> type;

  final List<int> payload;
}

/// Contenido de un registro NDEF: sabe convertirse en bytes y describirse.
abstract class NdefPayload {
  const NdefPayload(this.value);

  final String value;

  NdefRecordKind get kind;

  EncodedRecord encode();
}
