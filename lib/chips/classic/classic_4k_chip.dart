// Mifare Classic 4K: 40 sectores, 4096 bytes totales y 3440 de datos.

import 'classic_chip.dart';

/// Chip Mifare Classic de 4 KB de NXP (MF1S70yyX).
///
/// Los 32 primeros sectores tienen 4 bloques y los 8 últimos, 16.
class Classic4kChip extends ClassicChip {
  Classic4kChip(super.tag);

  /// SAK con el que responde al seleccionarlo.
  static const int sakValue = 0x18;

  /// ATQA de las variantes con NUID de 4 bytes.
  static const List<int> atqaShortUid = [0x00, 0x02];

  /// ATQA de las variantes con UID de 7 bytes.
  static const List<int> atqaLongUid = [0x00, 0x42];

  /// Sectores pequeños, de 4 bloques cada uno.
  static const int smallSectors = 32;

  @override
  String get name => 'Mifare Classic 4K';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  int get sectors => 40;

  @override
  int get blocks => 256;

  @override
  int get totalBytes => 4096;

  /// 216 bloques de datos menos el bloque de fabricante.
  @override
  int get dataBytes => 3440;

  @override
  int get sak => sakValue;

  @override
  int blocksInSector(int sector) => sector < smallSectors ? 4 : 16;
}
