// NTAG I2C plus 1K: 888 bytes de usuario y acceso por sectores.

import '../errors/not_implemented_error.dart';
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

/// Chip NTAG I2C plus de 1 KB (NT3H2111) de NXP.
///
/// La memoria se direcciona por sectores con SECTOR_SELECT; el contenido y la
/// configuración viven en el sector 0. No lleva contador de lecturas.
class NtagI2c1kChip extends Type2Chip
    implements
        Readable,
        Writable,
        Erasable,
        PasswordProtected,
        ReadProtected,
        OriginalitySigned,
        Identifiable {
  NtagI2c1kChip(super.tag);

  /// Página de los bytes de bloqueo dinámicos.
  static const int dynamicLock = 0xE2;

  /// Página con AUTH0 en el último byte.
  static const int auth0Page = 0xE3;

  /// Página con el byte ACCESS, que lleva NFC_PROT y AUTHLIM.
  static const int accessPage = 0xE4;

  /// Página que guarda la contraseña de 4 bytes.
  static const int pwd = 0xE5;

  /// Página que guarda el PACK (2 bytes) más 2 de relleno.
  static const int pack = 0xE6;

  /// Página con el byte PT_I2C, que configura el acceso desde el bus I2C.
  static const int ptI2c = 0xE7;

  /// Byte de tamaño que devuelve GET_VERSION.
  static const int storage = 0x13;

  /// Cambia el sector de memoria que se direcciona.
  static const int sectorSelect = 0xC2;

  @override
  String get name => 'NTAG I2C plus 1K';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  /// Byte de tamaño que devuelve GET_VERSION en este modelo.
  int get storageByte => storage;

  /// Bytes de contenido disponibles, en las páginas 04h-E1h del sector 0.
  int get userBytes => 888;

  /// Última página del mapa del sector 0; más allá empiezan los registros.
  int get lastPage => ptI2c;

  /// Página donde vive AUTH0.
  int get configPage0 => auth0Page;

  /// Página donde vive el byte ACCESS.
  int get configPage1 => accessPage;

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

  @override
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la ficha de la etiqueta');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');
}
