// ST25TV: 256 bytes de usuario repartidos en áreas con contraseña propia.

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

/// Chip ST25TV02K de STMicroelectronics.
///
/// La memoria se divide en áreas, cada una protegida en lectura y escritura
/// por su contraseña. El hermano ST25TV512 es igual con 16 bloques.
class St25tvChip extends NfcVChip
    implements
        Readable,
        Writable,
        Erasable,
        PasswordProtected,
        ReadProtected,
        OriginalitySigned,
        Counted,
        Identifiable {
  St25tvChip(super.tag);

  /// Write Password: cambia una contraseña ya presentada.
  static const int writePasswordCommand = 0xB1;

  /// Lock Kill: fija la contraseña de desactivación para siempre.
  static const int lockKill = 0xB2;

  /// Present Password: abre la sesión de seguridad de un área.
  static const int presentPassword = 0xB3;

  /// Get Random Number, con el que se cifra la contraseña al presentarla.
  static const int getRandomNumber = 0xB4;

  /// Kill: deja el chip mudo de forma irreversible.
  static const int kill = 0xA6;

  /// Enable Untraceable Mode: oculta UID y configuración al inventario.
  static const int enableUntraceableMode = 0xBA;

  /// Identificador de la contraseña de desactivación.
  static const int killPasswordId = 0x00;

  /// Identificadores de las contraseñas de las áreas de usuario.
  static const int area1PasswordId = 0x01;
  static const int area2PasswordId = 0x02;

  /// Identificador de la contraseña que cubre la configuración del sistema.
  static const int configPasswordId = 0x03;

  /// Tamaño de memoria que devuelve GET SYSTEM INFORMATION en este modelo.
  static const int memorySize = 0x033F;

  /// Bloque del área 0: siempre legible y bloqueable sin contraseña.
  static const int area0Block = 0x00;

  @override
  String get name => 'ST25TV';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  int get userBlocks => 64;

  @override
  int get blockSize => 4;

  @override
  int get userBytes => 256;

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
      throw NotImplementedError(name, 'la lectura de la firma TruST25');

  @override
  Future<int> readCounter() =>
      throw NotImplementedError(name, 'la lectura del contador de escrituras');

  @override
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la lectura de la ficha');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');
}
