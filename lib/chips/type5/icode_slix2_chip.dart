// ICODE SLIX2: 316 bytes de usuario y contraseñas por función.

import '../errors/not_implemented_error.dart';
import '../features/counted.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
import '../features/originality_signed.dart';
import '../features/password_protected.dart';
import '../features/read_protected.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import '../ndef/ndef_payload.dart';
import '../results/protection_result.dart';
import '../results/security_status.dart';
import '../results/tag_content.dart';
import '../results/tag_info.dart';
import '../results/write_report.dart';
import 'nfc_v_chip.dart';

/// Chip ICODE SLIX2 de NXP (SL2S2602).
///
/// Cada función tiene su contraseña de 32 bits, y las de lectura y escritura
/// protegen la memoria de usuario página a página.
class IcodeSlix2Chip extends NfcVChip
    implements
        Readable,
        Writable,
        Erasable,
        PasswordProtected,
        ReadProtected,
        OriginalitySigned,
        Counted,
        Identifiable {
  IcodeSlix2Chip(super.tag);

  /// GET RANDOM NUMBER, que abre el diálogo de contraseña.
  static const int getRandomNumber = 0xB2;

  /// SET PASSWORD: envía la contraseña cifrada con el número aleatorio.
  static const int setPasswordCommand = 0xB3;

  /// WRITE PASSWORD: cambia una contraseña ya presentada.
  static const int writePasswordCommand = 0xB4;

  /// PROTECT PAGE: asigna a cada página la contraseña que la cubre.
  static const int protectPage = 0xB6;

  /// ENABLE PRIVACY: deja el chip mudo hasta recibir su contraseña.
  static const int enablePrivacy = 0xBA;

  /// READ SIGNATURE: entrega la firma de originalidad de 32 bytes.
  static const int readSignatureCommand = 0xBD;

  /// GET NXP SYSTEM INFORMATION: estado de protección y de las contraseñas.
  static const int getNxpSystemInformation = 0xAB;

  /// Identificadores de las cinco contraseñas de 32 bits.
  static const int readPasswordId = 0x01;
  static const int writePasswordId = 0x02;
  static const int privacyPasswordId = 0x04;
  static const int destroyPasswordId = 0x08;
  static const int easAfiPasswordId = 0x10;

  /// Longitud de las contraseñas del chip en bytes.
  static const int passwordLength = 4;

  /// Bloque que guarda el contador de 16 bits; no admite datos de usuario.
  static const int counterBlock = 79;

  /// Longitud de la firma de originalidad en bytes, sobre la curva secp128r1.
  static const int signatureLength = 32;

  @override
  String get name => 'ICODE SLIX2';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  int get userBlocks => 79;

  @override
  int get blockSize => 4;

  @override
  int get userBytes => 316;

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
  Future<SecurityStatus> readSecurity({List<int> password = const []}) =>
      throw NotImplementedError(name, 'la lectura del estado de protección');

  @override
  Future<ProtectionResult> setPassword(
    List<int> password, {
    required int fromPage,
  }) => throw NotImplementedError(name, 'poner contraseña');

  @override
  Future<ProtectionResult> removePassword(List<int> password) =>
      throw NotImplementedError(name, 'quitar la contraseña');

  @override
  Future<ProtectionResult> setReadProtection(
    bool enabled, {
    List<int> password = const [],
  }) => throw NotImplementedError(name, 'la protección de lectura');

  @override
  Future<List<int>> readOriginalitySignature() =>
      throw NotImplementedError(name, 'la lectura de la firma de fábrica');

  @override
  Future<int> readCounter() =>
      throw NotImplementedError(name, 'la lectura del contador');

  @override
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la lectura de la ficha');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');
}
