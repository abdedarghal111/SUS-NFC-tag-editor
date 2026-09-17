// Tabla de prefijos de URI que el estándar comprime en un solo byte.

import 'dart:convert';

/// Prefijos de URI que el estándar NDEF sustituye por un código de un byte.
class UriPrefix {
  const UriPrefix._();

  static const Map<int, String> table = {
    0x00: '',
    0x01: 'http://www.',
    0x02: 'https://www.',
    0x03: 'http://',
    0x04: 'https://',
    0x05: 'tel:',
    0x06: 'mailto:',
    0x1D: 'file://',
  };

  /// Comprime un URI sustituyendo su prefijo conocido por el código.
  static List<int> compress(String uri) {
    for (final entry in table.entries) {
      if (entry.value.isNotEmpty && uri.startsWith(entry.value)) {
        return [entry.key, ...utf8.encode(uri.substring(entry.value.length))];
      }
    }
    return [0x00, ...utf8.encode(uri)];
  }

  /// Reconstruye el URI a partir del payload comprimido.
  static String expand(List<int> payload) {
    if (payload.isEmpty) return '';
    return (table[payload[0]] ?? '') +
        utf8.decode(payload.sublist(1), allowMalformed: true);
  }
}
