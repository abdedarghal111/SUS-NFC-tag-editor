// Mifare Ultralight EV1 MF0UL21: 128 bytes de usuario y contraseña.

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
import 'type2_chip.dart';

/// Chip Mifare Ultralight EV1 de 128 bytes (MF0UL21) de NXP.
///
/// Igual que el MF0UL11 pero con más memoria: las páginas de configuración se
/// van al final y aparece una página de bloqueos dinámicos.
class UltralightEv121Chip extends Type2Chip
    implements
        Readable,
        Writable,
        Erasable,
        PasswordProtected,
        ReadProtected,
        OriginalitySigned,
        Counted,
        Identifiable {
  UltralightEv121Chip(super.tag);

  /// Página de los bytes de bloqueo dinámicos.
  static const int dynamicLock = 0x24;

  /// CFG0, donde vive AUTH0 en el último byte.
  static const int cfg0 = 0x25;

  /// CFG1, con el byte ACCESS.
  static const int cfg1 = 0x26;

  /// Página que guarda la contraseña de 4 bytes.
  static const int pwd = 0x27;

  /// Página que guarda el PACK (2 bytes) más 2 de relleno.
  static const int pack = 0x28;

  /// Byte de tamaño que devuelve GET_VERSION.
  static const int storage = 0x0E;

  @override
  String get name => 'Mifare Ultralight EV1 (128 B)';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  /// Byte de tamaño que devuelve GET_VERSION en este modelo.
  int get storageByte => storage;

  /// Bytes de contenido disponibles para el usuario, en las páginas 04h-23h.
  int get userBytes => 128;

  /// Última página direccionable; leer más allá devuelve error.
  int get lastPage => pack;

  /// Página CFG0, donde vive AUTH0.
  int get configPage0 => cfg0;

  /// Página CFG1, con el byte ACCESS.
  int get configPage1 => cfg1;

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
      throw NotImplementedError(name, 'el borrado del contenido');

  @override
  Future<SecurityStatus> readSecurity({List<int> password = const []}) =>
      throw NotImplementedError(name, 'la lectura de la protección');

  @override
  Future<ProtectionResult> setPassword(
    List<int> password, {
    required int fromPage,
    bool protectReading = false,
  }) => throw NotImplementedError(name, 'poner contraseña');

  @override
  Future<ProtectionResult> removePassword(List<int> password) =>
      throw NotImplementedError(name, 'quitar la contraseña');

  @override
  Future<ProtectionResult> setReadProtection(
    bool enabled, {
    List<int> password = const [],
  }) => throw NotImplementedError(name, 'proteger también la lectura');

  @override
  Future<List<int>> readOriginalitySignature() =>
      throw NotImplementedError(name, 'la lectura de la firma de fábrica');

  /// Lee uno de los tres contadores de 24 bits, que solo suben.
  @override
  Future<int> readCounter() =>
      throw NotImplementedError(name, 'la lectura del contador');

  @override
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la ficha de la etiqueta');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');
}
