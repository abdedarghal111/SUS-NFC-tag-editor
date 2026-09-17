// Mifare Ultralight C: 144 bytes de usuario y autenticación 3DES.

import '../errors/not_implemented_error.dart';
import '../features/erasable.dart';
import '../features/readable.dart';
import '../features/writable.dart';
import '../ndef/ndef_payload.dart';
import '../results/tag_content.dart';
import '../results/write_report.dart';
import 'type2_chip.dart';

/// Chip Mifare Ultralight C (MF0ICU2) de NXP.
///
/// Protege la memoria con una clave 3DES de 16 bytes y el comando
/// AUTHENTICATE, no con la contraseña de 4 bytes de PWD_AUTH.
class UltralightCChip extends Type2Chip
    implements Readable, Writable, Erasable {
  UltralightCChip(super.tag);

  /// Página del contador de 16 bits, que solo sube.
  static const int counter = 0x29;

  /// Página de AUTH0: primera página protegida por la clave 3DES.
  static const int auth0 = 0x2A;

  /// Página de AUTH1: decide si la protección cubre también la lectura.
  static const int auth1 = 0x2B;

  /// Primera de las cuatro páginas donde vive la clave 3DES.
  static const int key = 0x2C;

  /// Última página direccionable; la memoria son 48 páginas en total.
  static const int last = 0x2F;

  /// Autenticación mutua 3DES en dos pasos.
  static const int authenticate = 0x1A;

  @override
  String get name => 'Mifare Ultralight C';

  @override
  bool get enabled => false;

  @override
  bool get devTested => false;

  /// Bytes de contenido disponibles para el usuario, en las páginas 04h-27h.
  int get userBytes => 144;

  /// Última página direccionable; leer más allá da la vuelta a la página 00h.
  int get lastPage => last;

  /// Página de AUTH0, el equivalente aquí a la página de configuración.
  int get configPage => auth0;

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
