// Mifare Classic 1K: 16 sectores, 1024 bytes totales y 752 de datos.

import 'classic_chip.dart';

/// Chip Mifare Classic de 1 KB de NXP (MF1S50yyX).
class Classic1kChip extends ClassicChip {
  Classic1kChip(super.tag);

  /// SAK con el que responde al seleccionarlo.
  static const int sakValue = 0x08;

  /// ATQA de las variantes con NUID de 4 bytes.
  static const List<int> atqaShortUid = [0x00, 0x04];

  /// ATQA de las variantes con UID de 7 bytes.
  static const List<int> atqaLongUid = [0x00, 0x44];

  @override
  String get name => 'Mifare Classic 1K';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  int get sectors => 16;

  @override
  int get blocks => 64;

  @override
  int get totalBytes => 1024;

  /// 48 bloques de datos menos el bloque de fabricante.
  @override
  int get dataBytes => 752;

  @override
  int get sak => sakValue;
}
