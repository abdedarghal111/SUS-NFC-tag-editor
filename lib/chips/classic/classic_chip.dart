// Base de la familia Mifare Classic: memoria por sectores con Crypto1.

import '../errors/not_implemented_error.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
import '../features/password_protected.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import '../ndef/ndef_payload.dart';
import '../nfc_chip.dart';
import '../results/protection_result.dart';
import '../results/security_status.dart';
import '../results/tag_content.dart';
import '../results/tag_info.dart';
import '../results/write_report.dart';

/// Chip Mifare Classic, solo accesible en teléfonos con radio compatible.
///
/// Recoge lo que vale para toda la familia: el juego de comandos, el tamaño de
/// bloque y el reparto del sector trailer, iguales en todos los modelos. El
/// número de sectores y de bloques lo pone cada chip.
abstract class ClassicChip extends NfcChip
    implements Readable, Writable, Erasable, PasswordProtected, Identifiable {
  ClassicChip(super.tag);

  /// Longitud de un bloque en bytes.
  static const int blockSize = 16;

  /// Bloque 0 del sector 0: UID y datos de fábrica, de solo lectura.
  static const int manufacturerBlock = 0;

  /// Longitud de la clave A y de la clave B dentro del sector trailer.
  static const int keyLength = 6;

  /// Posición de la clave A en el sector trailer: bytes 0 a 5.
  static const int keyAOffset = 0;

  /// Posición de los bits de acceso: bytes 6 a 9, el 9 libre para el usuario.
  static const int accessBitsOffset = 6;

  /// Longitud del campo de bits de acceso, con el byte de uso general.
  static const int accessBitsLength = 4;

  /// Posición de la clave B en el sector trailer: bytes 10 a 15.
  static const int keyBOffset = 10;

  /// Autenticación con la clave A del sector.
  static const int cmdAuthKeyA = 0x60;

  /// Autenticación con la clave B del sector.
  static const int cmdAuthKeyB = 0x61;

  /// Lee un bloque de 16 bytes.
  static const int cmdRead = 0x30;

  /// Escribe un bloque de 16 bytes.
  static const int cmdWrite = 0xA0;

  /// Resta al value block y deja el resultado en el búfer de transferencia.
  static const int cmdDecrement = 0xC0;

  /// Suma al value block y deja el resultado en el búfer de transferencia.
  static const int cmdIncrement = 0xC1;

  /// Copia un value block al búfer de transferencia.
  static const int cmdRestore = 0xC2;

  /// Vuelca el búfer de transferencia sobre un value block.
  static const int cmdTransfer = 0xB0;

  /// Número de sectores de la memoria.
  int get sectors;

  /// Número total de bloques, contando los sector trailers.
  int get blocks;

  /// Bytes totales de EEPROM.
  int get totalBytes;

  /// Bytes de datos utilizables, sin trailers ni bloque de fabricante.
  int get dataBytes;

  /// SAK con el que responde el chip al seleccionarlo.
  int get sak;

  /// Bloques que tiene el sector [sector], trailer incluido.
  int blocksInSector(int sector) => 4;

  /// Último bloque del sector [sector]: su sector trailer.
  int trailerBlock(int sector) =>
      firstBlockOf(sector) + blocksInSector(sector) - 1;

  /// Primer bloque del sector [sector].
  int firstBlockOf(int sector) {
    var block = 0;
    for (var i = 0; i < sector; i++) {
      block += blocksInSector(i);
    }
    return block;
  }

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
  Future<SecurityStatus> readSecurity({List<int> password = const []}) =>
      throw NotImplementedError(name, 'la lectura del estado de protección');

  @override
  Future<ProtectionResult> setPassword(
    List<int> password, {
    required int fromPage,
    bool protectReading = false,
  }) => throw NotImplementedError(name, 'poner la clave del sector');

  @override
  Future<ProtectionResult> removePassword(List<int> password) =>
      throw NotImplementedError(name, 'quitar la clave del sector');

  @override
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la lectura de la ficha de la etiqueta');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');
}
