// Ficha de la etiqueta y veredicto sobre su autenticidad.

import '../../utils/hex.dart';
import 'tag_result.dart';
import '../../chips/type2/auth0_layout.dart';
import '../../chips/type2/type2_chip.dart';

class TagInfo extends TagResult {
  const TagInfo({
    required this.uid,
    required this.atqa,
    required this.sak,
    required this.capacityBytes,
    required this.manufacturer,
    required this.product,
    required this.hasSignature,
    required this.config,
    required this.layout,
  });

  /// Identificador único de 7 bytes.
  final List<int> uid;

  /// Respuesta ATQA del protocolo ISO 14443-3A.
  final List<int> atqa;

  /// Respuesta SAK del protocolo ISO 14443-3A.
  final int sak;

  /// Bytes de contenido disponibles según el CC de la página 3.
  final int capacityBytes;

  /// Byte de fabricante de GET_VERSION; 0x04 en un chip NXP.
  final int? manufacturer;

  /// Byte de producto de GET_VERSION; 0x13 en un NTAG216.
  final int? product;

  final bool hasSignature;

  /// Los 4 bytes de CFG0 tal y como los devuelve la etiqueta.
  final List<int> config;

  /// Posición de AUTH0 con la que se interpreta CFG0.
  final Auth0Layout layout;

  /// Primera página protegida; 0xFF significa que no hay protección.
  int get auth0 => config.length == Type2Chip.pageSize
      ? config[layout.offset]
      : Type2Chip.noProtection;

  bool get isLocked => auth0 != Type2Chip.noProtection;

  String get protection {
    if (!isLocked) return 'Sin contraseña: cualquiera puede escribir.';
    if (auth0 == 0) {
      return 'Con contraseña desde la página 0: la etiqueta entera, '
          'configuración incluida.';
    }
    return 'Con contraseña desde la página $auth0.';
  }

  bool get isGenuineNxp => manufacturer == 0x04;

  bool get isNtag216 => product == 0x13;

  /// Explica si el chip parece auténtico o un clon, y por qué.
  String get authenticity {
    if (manufacturer == null) {
      return 'No responde a GET_VERSION: no es un NTAG21x de verdad.';
    }
    if (!isGenuineNxp) {
      return 'Clon compatible: declara el fabricante ${hexByte(manufacturer!)} '
          'en lugar de 0x04 (NXP).';
    }
    if (!hasSignature) {
      return 'Sospechoso: declara ser NXP pero no tiene firma grabada.';
    }
    return 'Parece un NTAG auténtico de NXP.';
  }

  @override
  String get summary => 'Etiqueta ${hexBytes(uid)} leída.';
}
