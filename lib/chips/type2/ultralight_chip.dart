// Mifare Ultralight original: 48 bytes de usuario, sin contraseña.

import '../errors/not_implemented_error.dart';
import '../features/erasable.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import '../ndef/ndef_payload.dart';
import '../results/tag_content.dart';
import '../results/write_report.dart';
import 'type2_chip.dart';

/// Chip Mifare Ultralight (MF0ICU1) de NXP.
///
/// Solo entiende READ, WRITE y COMPATIBILITY_WRITE: no lleva contraseña, ni
/// GET_VERSION, ni firma de fábrica, ni contador.
class UltralightChip extends Type2Chip implements Readable, Writable, Erasable {
  UltralightChip(super.tag);

  /// Última página direccionable; la memoria son 16 páginas en total.
  static const int last = 0x0F;

  /// Escritura de una página en dos tramas, heredada de Mifare Classic.
  static const int compatibilityWrite = 0xA0;

  @override
  String get name => 'Mifare Ultralight';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  /// Bytes de contenido disponibles para el usuario, en las páginas 04h-0Fh.
  int get userBytes => 48;

  /// Última página direccionable; leer más allá da la vuelta a la página 00h.
  int get lastPage => last;

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
}
