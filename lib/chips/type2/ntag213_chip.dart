// NTAG213: 144 bytes de usuario, configuración en la página 0x29.

import 'ntag21x_chip.dart';

/// Chip NTAG213 de NXP.
class Ntag213Chip extends Ntag21xChip {
  Ntag213Chip(super.tag);

  @override
  String get name => 'NTAG213';

  @override
  bool get enabled => true;

  @override
  bool get devTested => false;

  @override
  int get storageByte => 0x0F;

  @override
  int get userBytes => 144;

  @override
  int get lastPage => 0x2C;

  @override
  int get configPage0 => 0x29;
}
