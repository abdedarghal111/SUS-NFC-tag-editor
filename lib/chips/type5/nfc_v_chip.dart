// Base de la familia Type 5: ISO 15693, memoria en bloques y mayor alcance.

import '../nfc_chip.dart';

/// Chip de la familia Type 5 (NFC Forum), direccionado por UID.
///
/// Recoge lo que vale para toda la familia: el juego de comandos de ISO 15693
/// y la forma del UID. El tamaño de la memoria lo pone cada modelo.
abstract class NfcVChip extends NfcChip {
  NfcVChip(super.tag);

  /// Longitud del UID en bytes; ISO 15693 lo fija en 64 bits.
  static const int uidLength = 8;

  /// Primer byte del UID en todo chip ISO 15693.
  static const int uidPrefix = 0xE0;

  /// READ SINGLE BLOCK: devuelve un bloque y su estado de bloqueo.
  static const int readSingleBlock = 0x20;

  /// WRITE SINGLE BLOCK: graba un bloque entero.
  static const int writeSingleBlock = 0x21;

  /// LOCK BLOCK: deja un bloque en solo lectura de forma permanente.
  static const int lockBlock = 0x22;

  /// READ MULTIPLE BLOCKS: lee bloques consecutivos de una pasada.
  static const int readMultipleBlocks = 0x23;

  /// GET SYSTEM INFORMATION: devuelve UID, DSFID, AFI, número de bloques,
  /// tamaño de bloque y referencia del IC.
  static const int getSystemInformation = 0x2B;

  /// GET MULTIPLE BLOCK SECURITY STATUS: estado de bloqueo de varios bloques.
  static const int getMultipleBlockSecurityStatus = 0x2C;

  /// Bloques de usuario direccionables.
  int get userBlocks;

  /// Longitud de un bloque en bytes.
  int get blockSize;

  /// Bytes de contenido disponibles para el usuario.
  int get userBytes;

  /// Indica si admite LOCK BLOCK, que protege un bloque para siempre.
  bool get canLockBlocks;
}
