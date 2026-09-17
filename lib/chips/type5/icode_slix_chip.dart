// ICODE SLIX: 112 bytes de usuario y contraseña de EAS/AFI.

import '../errors/not_implemented_error.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import '../ndef/ndef_payload.dart';
import '../results/tag_content.dart';
import '../results/tag_info.dart';
import '../results/write_report.dart';
import 'nfc_v_chip.dart';

/// Chip ICODE SLIX de NXP (SL2S2002 y SL2S2102).
///
/// La contraseña de 32 bits solo cubre EAS y AFI: la memoria de usuario se
/// escribe sin autenticarse y se protege bloqueando bloques.
class IcodeSlixChip extends NfcVChip
    implements Readable, Writable, Erasable, Identifiable {
  IcodeSlixChip(super.tag);

  /// GET RANDOM NUMBER, que abre el diálogo de contraseña.
  static const int getRandomNumber = 0xB2;

  /// SET PASSWORD: envía la contraseña cifrada con el número aleatorio.
  static const int setPasswordCommand = 0xB3;

  /// Identificador de la única contraseña del chip, la de EAS/AFI.
  static const int easAfiPasswordId = 0x10;

  /// Longitud de las contraseñas del chip en bytes.
  static const int passwordLength = 4;

  @override
  String get name => 'ICODE SLIX';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  int get userBlocks => 28;

  @override
  int get blockSize => 4;

  @override
  int get userBytes => 112;

  @override
  bool get canLockBlocks => true;

  @override
  Future<TagContent> readContent({List<int> password = const []}) =>
      throw NotImplementedError(name, 'la lectura de contenido');

  @override
  Future<WriteReport> writeContent(
    List<NdefPayload> payloads, {
    List<int> password = const [],
  }) => throw NotImplementedError(name, 'la escritura de contenido');

  @override
  Future<WriteReport> eraseContent({List<int> password = const []}) =>
      throw NotImplementedError(name, 'el borrado de contenido');

  @override
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la lectura de la ficha');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');
}
