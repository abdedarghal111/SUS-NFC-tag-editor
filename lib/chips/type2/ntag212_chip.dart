// NTAG212: 128 bytes de usuario, configuración en la página 0x25.

import 'ntag21x_chip.dart';

/// Chip NTAG212 de NXP.
class Ntag212Chip extends Ntag21xChip {
  Ntag212Chip(super.tag);

  @override
  String get name => 'NTAG212';

  @override
  bool get enabled => true;

  @override
  bool get devTested => false;

  @override
  int get storageByte => 0x0E;

  @override
  int get userBytes => 128;

  @override
  int get lastPage => 0x28;

  @override
  int get configPage0 => 0x25;
}
