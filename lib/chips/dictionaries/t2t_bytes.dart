// Traducción del Capability Container, que define la especificación NFC Forum
// Type 2 Tag y llevan todas las etiquetas de esa familia.

import '../../utils/hex.dart';

/// Qué dicen los 4 bytes del CC, que vive en la página 3.
///
/// Entrada: los 4 bytes. Salida: una frase por cada cosa que declaran.
List<String> describeCapabilityContainer(List<int> cc) {
  if (cc.length != 4) return const [];

  final [magic, version, size, access] = cc;

  return [
    if (magic == 0xE1)
      'NDEF v${version >> 4}.${version & 0x0F}'
    else
      'sin la marca NDEF 0xE1',
    '${size * 8} B',
    switch (access) {
      0x00 => 'lectura y escritura libres',
      0x0F => 'solo lectura',
      _ => 'permisos ${hexByte(access)}, poco habituales',
    },
  ];
}
