// Mifare DESFire EV2: EV1 con delegación de aplicaciones y prueba de proximidad.

import '../errors/not_implemented_error.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
import '../features/originality_signed.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import '../ndef/ndef_payload.dart';
import '../results/tag_content.dart';
import '../results/tag_info.dart';
import '../results/write_report.dart';
import 'iso_dep_chip.dart';

/// Chip Mifare DESFire EV2 de NXP (MF3D(H)x2).
///
/// Quita el tope de 28 aplicaciones del EV1 y añade la firma ECC de fábrica,
/// la prueba de proximidad y el fichero Transaction MAC.
class DesfireEv2Chip extends IsoDepChip
    implements Readable, Writable, Erasable, Identifiable, OriginalitySigned {
  DesfireEv2Chip(super.tag);

  /// Ficheros por aplicación, de seis tipos distintos.
  static const int filesPerApplication = 32;

  /// Claves por aplicación, más la clave maestra de la tarjeta.
  static const int keysPerApplication = 14;

  /// Juegos de claves por aplicación, para relevarlas sin parar el servicio.
  static const int keySetsPerApplication = 16;

  @override
  String get name => 'Mifare DESFire EV2';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  List<int> get storageSizes => const [2048, 4096, 8192, 16384, 32768];

  @override
  bool get usesAes => true;

  @override
  bool get usesTripleDes => true;

  @override
  int get maxApplications => IsoDepChip.applicationsLimitedByMemory;

  @override
  int get maxFilesPerApplication => filesPerApplication;

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
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la lectura de la ficha');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');

  @override
  Future<List<int>> readOriginalitySignature() =>
      throw NotImplementedError(name, 'la lectura de la firma de fábrica');
}
