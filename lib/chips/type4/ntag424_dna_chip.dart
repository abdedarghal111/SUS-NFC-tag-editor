// NTAG 424 DNA: firma distinta en cada lectura, con AES y contador.

import '../errors/not_implemented_error.dart';
import '../features/counted.dart';
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

/// Chip NTAG 424 DNA de NXP (NT4H2421Gx).
///
/// Una sola aplicación con tres ficheros fijos que no se pueden borrar ni
/// crear: capacidades, NDEF y datos protegidos.
class Ntag424DnaChip extends IsoDepChip
    implements
        Readable,
        Writable,
        Erasable,
        Identifiable,
        OriginalitySigned,
        Counted {
  Ntag424DnaChip(super.tag);

  /// Memoria total repartida entre los tres ficheros, en bytes.
  static const int storage = 416;

  /// Fichero de capacidades (CC), de 32 bytes.
  static const int capabilityFileBytes = 32;

  /// Fichero NDEF, de 256 bytes.
  static const int ndefFileBytes = 256;

  /// Fichero de datos protegidos, de 128 bytes.
  static const int protectedFileBytes = 128;

  /// Claves AES de 128 bits que configura el cliente.
  static const int keys = 5;

  /// Bits del contador de lecturas (SDMReadCtr), que sube en cada toque.
  static const int counterBits = 24;

  @override
  String get name => 'NTAG 424 DNA';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  List<int> get storageSizes => const [storage];

  @override
  bool get usesAes => true;

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
  Future<TagInfo> readInfo() =>
      throw NotImplementedError(name, 'la lectura de la ficha');

  @override
  Future<bool> matchesTag() =>
      throw NotImplementedError(name, 'la comprobación del modelo');

  @override
  Future<List<int>> readOriginalitySignature() =>
      throw NotImplementedError(name, 'la lectura de la firma de fábrica');

  @override
  Future<int> readCounter() =>
      throw NotImplementedError(name, 'la lectura del contador');
}
