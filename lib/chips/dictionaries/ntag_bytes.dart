// Traducción de los bytes propios de la familia NTAG21x: los que devuelve
// GET_VERSION y los de las páginas de configuración.
//
// Los valores salen de la hoja de datos NTAG213/215/216 de NXP, rev. 3.2.
// Están recogidos en docs/ntag213-215-216.md.

import '../../utils/hex.dart';
import '../type2/type2_chip.dart';

/// Modelos que declara el byte de tamaño de GET_VERSION, con su memoria de
/// usuario en bytes (tabla 28).
const Map<int, (String, int)> storageSizes = {
  0x0F: ('NTAG213', 144),
  0x11: ('NTAG215', 504),
  0x13: ('NTAG216', 888),
};

/// Tipos de producto que declara el byte 2 de GET_VERSION.
const Map<int, String> productTypes = {0x04: 'NTAG'};

/// Qué modelo declara el byte de tamaño de GET_VERSION.
List<String> describeStorageSize(int code) {
  final model = storageSizes[code];
  if (model != null) return ['${model.$1}, ${model.$2} B'];
  return const ['fuera de la familia; serían 0x0F, 0x11 o 0x13'];
}

/// Qué dicen los 4 bytes de CFG0 (tablas 8, 9 y 11).
///
/// CFG0 es `[MIRROR, RFUI, MIRROR_PAGE, AUTH0]`.
List<String> describeConfig0(List<int> config) {
  if (config.length != Type2Chip.pageSize) return const [];

  final mirror = config[0];
  final mirrorPage = config[2];

  return [
    _mirrorMode(mirror >> 6),
    if (mirror & 0x08 != 0) 'modulación fuerte',
    if (mirrorPage > 0x03) 'espejo desde la página $mirrorPage',
    'AUTH0 ${hexByte(config[Type2Chip.auth0Offset])}: '
        '${describeAuth0(config[Type2Chip.auth0Offset])}',
  ];
}

/// Qué protege el valor de AUTH0.
String describeAuth0(int auth0) {
  if (auth0 == Type2Chip.noProtection) return 'sin protección';
  if (auth0 == 0) return 'protegida entera, configuración incluida';
  return 'protegida desde la página $auth0';
}

/// Qué dicen los bits del byte ACCESS, que vive en CFG1 (tabla 10).
List<String> describeAccess(int access) {
  final limit = access & Type2Chip.authLimitMask;

  return [
    access & Type2Chip.protectReadMask != 0
        ? 'PROT: protege leer y escribir'
        : 'PROT: solo protege escribir',
    if (access & 0x40 != 0) 'CFGLCK: configuración cerrada para siempre',
    if (access & 0x10 != 0) 'contador activado',
    if (access & 0x08 != 0) 'contador con contraseña',
    limit == 0
        ? 'AUTHLIM: intentos ilimitados'
        : 'AUTHLIM: $limit fallos y se cierra para siempre',
  ];
}

/// Qué significa lo que la etiqueta devuelve al leer PWD y PACK.
///
/// Un chip que cumple contesta ceros; si devuelve otra cosa está enseñando su
/// propia contraseña.
List<String> describeStoredPassword(List<int> password, List<int> pack) {
  final leaks =
      password.any((byte) => byte != 0) || pack.any((byte) => byte != 0);
  return [
    leaks
        ? 'los enseña al leerlos: la protección no sirve'
        : 'ceros, como debe ser',
  ];
}

String _mirrorMode(int conf) => switch (conf) {
  0 => 'sin espejo',
  1 => 'espejo del UID',
  2 => 'espejo del contador',
  _ => 'espejo del UID y del contador',
};
