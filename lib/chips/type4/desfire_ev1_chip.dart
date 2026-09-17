// Mifare DESFire EV1: aplicaciones y ficheros con cifrado 3DES y AES.

import '../errors/not_implemented_error.dart';
import '../features/erasable.dart';
import '../features/identifiable.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import '../ndef/ndef_payload.dart';
import '../results/tag_content.dart';
import '../results/tag_info.dart';
import '../results/write_report.dart';
import 'iso_dep_chip.dart';

/// Chip Mifare DESFire EV1 de NXP (MF3ICD21, MF3ICD41 y MF3ICD81).
///
/// Lee y escribe NDEF solo si la etiqueta lleva creada la aplicación NDEF del
/// NFC Forum; de fábrica viene sin ella.
class DesfireEv1Chip extends IsoDepChip
    implements Readable, Writable, Erasable, Identifiable {
  DesfireEv1Chip(super.tag);

  /// Aplicaciones que caben a la vez en la etiqueta.
  static const int applications = 28;

  /// Ficheros por aplicación, de cinco tipos distintos.
  static const int filesPerApplication = 32;

  /// Claves por aplicación, más la clave maestra de la tarjeta.
  static const int keysPerApplication = 14;

  @override
  String get name => 'Mifare DESFire EV1';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  List<int> get storageSizes => const [2048, 4096, 8192];

  @override
  bool get usesAes => true;

  @override
  bool get usesTripleDes => true;

  @override
  int get maxApplications => applications;

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
}
