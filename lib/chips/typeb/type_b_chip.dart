// Base de la familia NFC-B: ISO 14443-B, con su propio saludo de selección.

import '../nfc_chip.dart';

/// Chip que habla ISO 14443-B.
///
/// Recoge la forma de la memoria, que en esta familia va por bloques en vez de
/// por páginas. Los comandos los pone cada chip: no hay un juego común.
abstract class TypeBChip extends NfcChip {
  TypeBChip(super.tag);

  /// Longitud de un bloque en bytes.
  int get blockSize;

  /// Bloques que tiene la memoria direccionable.
  int get blockCount;

  /// Bytes de contenido disponibles para el usuario.
  int get userBytes;

  /// Bytes totales de la memoria direccionable.
  int get totalBytes;
}
