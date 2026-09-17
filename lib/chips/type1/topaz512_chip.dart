// Topaz 512: 480 bytes de usuario en 64 bloques repartidos en 4 segmentos.

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

/// Chip Topaz de 512 bytes (BCM20203T512).
///
/// La versión dinámica de la familia: añade los comandos de segmento y de
/// bloque de 8 bytes para llegar más allá del bloque 0x0E.
class Topaz512Chip extends Type1Chip
    implements Readable, Writable, Erasable, Identifiable {
  Topaz512Chip(super.tag);

  /// Bloques que ocupa un segmento; son 128 bytes.
  static const int blocksPerSegment = 16;

  /// Segmentos que implementa el chip.
  static const int segments = 4;

  /// Bloque 0x0E: bytes LOCK-0 y LOCK-1, que cubren los bloques 0x00 a 0x0F.
  static const int lockBlock = 0x0E;

  /// Bloque 0x0F: OTP-6 y OTP-7 más LOCK-2 a LOCK-7, para el resto de bloques.
  static const int dynamicLockBlock = 0x0F;

  /// RSEG: lee los 128 bytes de un segmento entero.
  static const int cmdReadSegment = 0x10;

  /// READ8: lee un bloque completo de 8 bytes.
  static const int cmdRead8 = 0x02;

  /// WRITE-E8: escribe un bloque de 8 bytes borrando antes su contenido.
  static const int cmdWriteErase8 = 0x54;

  /// WRITE-NE8: escribe un bloque de 8 bytes sin borrarlo.
  static const int cmdWriteNoErase8 = 0x1B;

  @override
  String get name => 'Topaz 512';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  int get userBytes => 480;

  @override
  int get totalBytes => 512;

  @override
  int get lastBlock => 0x3F;

  @override
  int get headerRom0 => 0x12;

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
