// SRI512: 16 bloques de 4 bytes, de los que 9 son área de usuario.

import '../errors/not_implemented_error.dart';
import '../features/identifiable.dart';
import '../results/tag_info.dart';
import 'type_b_chip.dart';

/// Chip SRI512 de STMicroelectronics.
///
/// Memoria de 512 bits con área OTP, dos contadores descendentes y bloqueo por
/// bloque. No es NFC Forum: no entiende NDEF ni admite contraseña.
class Sri512Chip extends TypeBChip implements Identifiable {
  Sri512Chip(super.tag);

  /// Bloques 0 a 4: área OTP, cuyos bits solo pasan de 1 a 0.
  static const int firstOtpBlock = 0x00;

  /// Bloques 5 y 6: contadores descendentes de 32 bits.
  static const int firstCounterBlock = 0x05;

  /// Bloques 7 a 15: EEPROM de usuario, la única parte reescribible.
  static const int firstUserBlock = 0x07;

  /// Bloque 255: zona de sistema con el registro de bloqueo y el Chip_ID.
  static const int systemBlock = 0xFF;

  /// Initiate: arranca la anticolisión.
  static const List<int> cmdInitiate = [0x06, 0x00];

  /// Pcall16: reparte las etiquetas en los 16 huecos de la anticolisión.
  static const List<int> cmdPcall16 = [0x06, 0x04];

  /// Select: fija el Chip_ID con el que se trabaja; obligatorio antes de leer.
  static const int cmdSelect = 0x0E;

  /// Read_block: lee los 4 bytes de un bloque.
  static const int cmdReadBlock = 0x08;

  /// Write_block: escribe los 4 bytes de un bloque de una vez.
  static const int cmdWriteBlock = 0x09;

  /// Get_UID: entrega el UID de 8 bytes, que no es direccionable como bloque.
  static const int cmdGetUid = 0x0B;

  /// Reset_to_inventory: devuelve la etiqueta a la anticolisión.
  static const int cmdResetToInventory = 0x0C;

  /// Completion: deja la etiqueta callada hasta que se quite del campo.
  static const int cmdCompletion = 0x0F;

  @override
  String get name => 'SRI512';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  int get blockSize => 4;

  @override
  int get blockCount => 16;

  @override
  int get userBytes => 36;

  @override
  int get totalBytes => 64;

  @override
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la lectura de la ficha');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');
}
