// NTAG210: 48 bytes de usuario, configuración en la página 0x10.

import 'ntag21x_chip.dart';

/// Chip NTAG210 de NXP.
///
/// El modelo más pequeño de la serie: 48 bytes de contenido y sin contador de
/// lecturas.
class Ntag210Chip extends Ntag21xChip {
  Ntag210Chip(super.tag);

  @override
  String get name => 'NTAG210';

  @override
  bool get enabled => true;

  @override
  bool get devTested => false;

  @override
  bool get hasNfcCounter => false;

  @override
  int get storageByte => 0x0B;

  @override
  int get userBytes => 48;

  @override
  int get lastPage => 0x13;

  @override
  int get configPage0 => 0x10;
}
