// NTAG215: 504 bytes de usuario, configuración en la página 0x83.

import 'ntag21x_chip.dart';

/// Chip NTAG215 de NXP.
class Ntag215Chip extends Ntag21xChip {
  Ntag215Chip(super.tag);

  @override
  String get name => 'NTAG215';

  @override
  bool get enabled => true;

  @override
  bool get devTested => false;

  @override
  int get storageByte => 0x11;

  @override
  int get userBytes => 504;

  @override
  int get lastPage => 0x86;

  @override
  int get configPage0 => 0x83;
}
