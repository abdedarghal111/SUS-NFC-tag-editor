// Base de la familia Type 1: protocolo Jewel sobre NFC-A, en bloques de 8 bytes.

import '../nfc_chip.dart';

/// Chip de la familia Type 1 (NFC Forum), heredero de Topaz de Innovision.
///
/// Recoge lo que vale para toda la familia: el juego de comandos estáticos, el
/// tamaño de bloque y los bloques de cabecera. Los tamaños los pone cada chip.
abstract class Type1Chip extends NfcChip {
  Type1Chip(super.tag);

  /// Longitud de un bloque en bytes.
  static const int blockSize = 8;

  /// Bloque 0: UID de 7 bytes más un byte reservado.
  static const int uidBlock = 0x00;

  /// Bloque 1: sus cuatro primeros bytes son el Capability Container.
  static const int capabilityBlock = 0x01;

  /// Longitud del UID en bytes; los comandos solo repiten los 4 últimos.
  static const int uidLength = 7;

  /// RID: devuelve la cabecera ROM y los cuatro primeros bytes del UID.
  static const int cmdRid = 0x78;

  /// RALL: lee de una vez los bloques 0x00 a 0x0E.
  static const int cmdReadAll = 0x00;

  /// READ: lee un byte suelto.
  static const int cmdRead = 0x01;

  /// WRITE-E: escribe un byte borrando antes su contenido.
  static const int cmdWriteErase = 0x53;

  /// WRITE-NE: escribe un byte sin borrarlo; solo pone bits a 1.
  static const int cmdWriteNoErase = 0x1A;

  /// Bytes de contenido disponibles para el usuario.
  int get userBytes;

  /// Bytes totales de la EEPROM, cabecera y bloqueos incluidos.
  int get totalBytes;

  /// Último bloque direccionable.
  int get lastBlock;

  /// Valor de HR0 con el que la etiqueta declara de qué modelo es.
  int get headerRom0;
}
