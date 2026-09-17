// FeliCa estándar: varias aplicaciones y servicios con claves propias.

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

/// Chip FeliCa estándar de Sony.
///
/// La memoria se reparte en sistemas, áreas y servicios que el emisor define
/// al personalizar la tarjeta, cada uno con su clave y su autenticación mutua.
class FelicaStandardChip extends NfcFChip
    implements Readable, Writable, Erasable, Identifiable {
  FelicaStandardChip(super.tag);

  /// Request Service: consulta la versión de clave de un servicio.
  static const int requestService = 0x02;

  /// Request System Code: enumera los sistemas emitidos en la tarjeta.
  static const int requestSystemCode = 0x0C;

  @override
  String get name => 'FeliCa estándar';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  /// Código de sistema del área NDEF; los demás los fija el emisor.
  @override
  int get systemCode => NfcFChip.ndefSystemCode;

  /// El reparto de la memoria depende del producto y de cómo se emitiera.
  @override
  int get userBlocks => 0;

  @override
  int get userBytes => 0;

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
