// Mifare Classic Mini: 5 sectores, 320 bytes totales y 224 de datos.

import 'classic_chip.dart';

/// Chip Mifare Classic Mini (S20) de NXP.
class ClassicMiniChip extends ClassicChip {
  ClassicMiniChip(super.tag);

  /// SAK con el que responde al seleccionarlo.
  static const int sakValue = 0x09;

  @override
  String get name => 'Mifare Classic Mini';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  int get sectors => 5;

  @override
  int get blocks => 20;

  @override
  int get totalBytes => 320;

  /// 15 bloques de datos menos el bloque de fabricante.
  @override
  int get dataBytes => 224;

  @override
  int get sak => sakValue;
}
