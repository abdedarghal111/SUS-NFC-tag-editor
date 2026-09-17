// NTAG216F: como el 216, con detección de campo por interrupción.

import 'ntag21x_chip.dart';

/// Chip NTAG216F de NXP.
class Ntag216fChip extends Ntag21xChip {
  Ntag216fChip(super.tag);

  @override
  String get name => 'NTAG216F';

  @override
  bool get enabled => true;

  @override
  bool get devTested => false;

  @override
  int get storageByte => 0x13;

  @override
  int get userBytes => 888;

  @override
  int get lastPage => 0xE6;

  @override
  int get configPage0 => 0xE3;
}
