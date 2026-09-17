// Topaz 96: 96 bytes de usuario en 15 bloques de 8, sin comandos dinámicos.

import '../errors/not_implemented_error.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import '../ndef/ndef_payload.dart';
import '../results/tag_content.dart';
import '../results/tag_info.dart';
import '../results/write_report.dart';
import 'type1_chip.dart';

/// Chip Topaz de 96 bytes (BCM20203T96).
///
/// La versión estática de la familia: solo los cinco comandos básicos y una
/// memoria que cabe entera en una respuesta a RALL.
class Topaz96Chip extends Type1Chip
    implements Readable, Writable, Erasable, Identifiable {
  Topaz96Chip(super.tag);

  /// Bloques 1 a 0x0C, los que guardan contenido.
  static const int firstDataBlock = 0x01;

  /// Bloque 0x0E: bytes LOCK-0 y LOCK-1 más los 6 bytes OTP.
  static const int lockBlock = 0x0E;

  @override
  String get name => 'Topaz 96';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  int get userBytes => 96;

  @override
  int get totalBytes => 120;

  @override
  int get lastBlock => 0x0E;

  @override
  int get headerRom0 => 0x11;

  @override
  Future<TagContent> readContent({List<int> password = const []}) =>
      throw NotImplementedError(name, 'la lectura de contenido');

  @override
  Future<WriteReport> writeContent(
    List<NdefPayload> payloads, {
    List<int> password = const [],
  }) => throw NotImplementedError(name, 'la escritura de contenido');

  @override
  Future<WriteReport> eraseContent({List<int> password = const []}) =>
      throw NotImplementedError(name, 'el borrado del contenido');

  @override
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la lectura de la ficha');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');
}
