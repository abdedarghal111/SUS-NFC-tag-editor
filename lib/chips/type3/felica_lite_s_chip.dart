// FeliCa Lite-S: 224 bytes de usuario, con firma MAC por bloque.

import '../errors/not_implemented_error.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import '../ndef/ndef_payload.dart';
import '../results/tag_content.dart';
import '../results/tag_info.dart';
import '../results/write_report.dart';
import 'nfc_f_chip.dart';

/// Chip FeliCa Lite-S de Sony (RC-S966).
///
/// No lleva contraseñas: el acceso restringido se resuelve con una clave de
/// tarjeta y un MAC en T-DES que se calcula bloque a bloque.
class FelicaLiteSChip extends NfcFChip
    implements Readable, Writable, Erasable, Identifiable {
  FelicaLiteSChip(super.tag);

  /// Primer bloque de usuario, S_PAD0.
  static const int firstUserBlock = 0x00;

  /// Último bloque de usuario, S_PAD13.
  static const int lastUserBlock = 0x0D;

  /// REG: registro de resta, fuera de los bloques de contenido.
  static const int registerBlock = 0x0E;

  /// ID: guarda el identificador de la tarjeta y su bloqueo.
  static const int idBlock = 0x82;

  /// CKV: versión de la clave de tarjeta.
  static const int cardKeyVersionBlock = 0x86;

  /// CK: clave de tarjeta con la que se calculan los MAC.
  static const int cardKeyBlock = 0x87;

  /// MC: fija los permisos de lectura y escritura de cada bloque.
  static const int memoryConfigBlock = 0x88;

  /// WCNT: contador de escrituras que entra en el cálculo del MAC.
  static const int writeCounterBlock = 0x90;

  /// MAC_A: por donde se leen y escriben los MAC de autenticación mutua.
  static const int macBlock = 0x91;

  @override
  String get name => 'FeliCa Lite-S';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  /// Código de sistema propio; también responde a 12FCh si se activa el NDEF.
  @override
  int get systemCode => 0x88B4;

  @override
  int get userBlocks => 14;

  @override
  int get userBytes => 224;

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
