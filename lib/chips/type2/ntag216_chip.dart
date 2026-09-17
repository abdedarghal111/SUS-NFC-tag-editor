// NTAG216: 888 bytes de usuario, configuración en la página 0xE3.

import 'ntag21x_chip.dart';

/// Chip NTAG216 de NXP.
///
/// El modelo para el que se escribió la app: el único probado contra etiquetas
/// reales, originales y clones.
class Ntag216Chip extends Ntag21xChip {
  Ntag216Chip(super.tag);

  /// CFG0 = [MIRROR, RFUI, MIRROR_PAGE, AUTH0].
  static const int cfg0 = 0xE3;

  /// Página que guarda la contraseña de 4 bytes.
  static const int pwd = 0xE5;

  /// Página que guarda el PACK (2 bytes) más 2 de relleno.
  static const int pack = 0xE6;

  /// Byte de tamaño que devuelve GET_VERSION.
  static const int storage = 0x13;

  @override
  String get name => 'NTAG216';

  @override
  bool get enabled => true;

  @override
  bool get devTested => true;

  @override
  int get storageByte => storage;

  @override
  int get userBytes => 888;

  @override
  int get lastPage => pack;

  @override
  int get configPage0 => cfg0;
}
