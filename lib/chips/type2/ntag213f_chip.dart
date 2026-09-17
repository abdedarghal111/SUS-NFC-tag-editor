// NTAG213F: como el 213, con detección de campo por interrupción.

import 'ntag21x_chip.dart';

/// Chip NTAG213F de NXP.
class Ntag213fChip extends Ntag21xChip {
  Ntag213fChip(super.tag);

  @override
  String get name => 'NTAG213F';

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
