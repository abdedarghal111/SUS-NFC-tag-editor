// Mifare Plus: memoria por sectores como el Classic, pero con AES.

import '../errors/not_implemented_error.dart';
import '../features/identifiable.dart';
import '../features/originality_signed.dart';
import '../results/tag_info.dart';
import 'iso_dep_chip.dart';

/// Chip Mifare Plus EV2 de NXP (MF1P(H)x2).
///
/// No tiene sistema de ficheros: la memoria va en sectores de bloques, como en
/// el Classic, y el nivel de seguridad decide si se usa Crypto1 o AES.
class MifarePlusChip extends IsoDepChip
    implements Identifiable, OriginalitySigned {
  MifarePlusChip(super.tag);

  /// Sectores de la variante de 2 kB: 32 sectores de 4 bloques.
  static const int sectors2k = 32;

  /// Sectores de la variante de 4 kB: los 32 anteriores más 8 de 16 bloques.
  static const int sectors4k = 40;

  /// Nivel de seguridad más bajo: compatible con Mifare Classic EV1.
  static const int securityLevel1 = 1;

  /// Nivel de seguridad más alto: AES obligatorio en todo el diálogo.
  static const int securityLevel3 = 3;

  @override
  String get name => 'Mifare Plus';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  @override
  List<int> get storageSizes => const [2048, 4096];

  @override
  bool get usesAes => true;

  @override
  bool get usesTripleDes => false;

  @override
  int get maxApplications => IsoDepChip.withoutApplications;

  @override
  int get maxFilesPerApplication => 0;

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
