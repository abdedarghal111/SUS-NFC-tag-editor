// ST25TA: Type 4 de STMicroelectronics, con contraseña por fichero.

import '../errors/not_implemented_error.dart';
import '../features/counted.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
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
import 'iso_dep_chip.dart';

/// Chip ST25TA de STMicroelectronics.
///
/// Una aplicación NDEF con tres ficheros: capacidades, NDEF y el fichero de
/// sistema propio de ST, donde viven el contador y la configuración.
class St25taChip extends IsoDepChip
    implements
        Readable,
        Writable,
        Erasable,
        PasswordProtected,
        ReadProtected,
        Counted,
        Identifiable {
  St25taChip(super.tag);

  /// Bits de cada contraseña: una para leer y otra para escribir.
  static const int passwordBits = 128;

  /// Bits del contador de eventos, con mecanismo antirrotura.
  static const int counterBits = 20;

  /// Bytes que se pueden leer de una vez.
  static const int maxReadBytes = 255;

  /// Bytes que se pueden escribir de una vez.
  static const int maxWriteBytes = 54;

  @override
  String get name => 'ST25TA';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  List<int> get storageSizes => const [256, 2048, 8192];

  @override
  bool get usesAes => false;

  @override
  bool get usesTripleDes => false;

  @override
  int get maxApplications => 1;

  @override
  int get maxFilesPerApplication => 3;

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
      throw NotImplementedError(name, 'la lectura del estado de protección');

  @override
  Future<ProtectionResult> setPassword(
    List<int> password, {
    required int fromPage,
  }) => throw NotImplementedError(name, 'poner la contraseña');

  @override
  Future<ProtectionResult> removePassword(List<int> password) =>
      throw NotImplementedError(name, 'quitar la contraseña');

  @override
  Future<ProtectionResult> setReadProtection(
    bool enabled, {
    List<int> password = const [],
  }) => throw NotImplementedError(name, 'la protección de la lectura');

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
