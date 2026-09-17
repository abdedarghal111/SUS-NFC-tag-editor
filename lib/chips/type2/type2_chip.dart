// Base de la familia Type 2: memoria en páginas de 4 bytes sobre NFC-A.

import 'dart:typed_data';

import '../../utils/hex.dart';
import '../nfc_chip.dart';
import 'auth0_layout.dart';

/// Chip de la familia Type 2 (NFC Forum), con READ 0x30 y WRITE 0xA2.
///
/// Recoge lo que vale para toda la familia: el juego de comandos, el tamaño de
/// página y los bits de configuración, que significan lo mismo en todos los
/// modelos. Las direcciones concretas las pone cada chip.
abstract class Type2Chip extends NfcChip {
  Type2Chip(super.tag);

  /// Longitud de una página en bytes.
  static const int pageSize = 4;

  /// Primera página de contenido; las 0-3 son cabecera de solo lectura.
  static const int firstDataPage = 4;

  /// Valor de AUTH0 que desactiva la protección.
  static const int noProtection = 0xFF;

  /// Bit PROT de ACCESS: extiende la protección a la lectura.
  static const int protectReadMask = 0x80;

  /// Bits AUTHLIM de ACCESS: fallos tolerados antes del bloqueo permanente.
  static const int authLimitMask = 0x07;

  /// Indica si escribir en [page] exige autenticarse.
  static bool requiresAuth(int auth0, int page) =>
      auth0 != noProtection && page >= auth0;

  /// Devuelve CFG0 con AUTH0 cambiado y el resto de bytes intactos.
  static List<int> withAuth0(List<int> config, int auth0, Auth0Layout layout) {
    final updated = [...config];
    updated[layout.offset] = auth0;
    return updated;
  }

  /// Lee 16 bytes, es decir cuatro páginas consecutivas desde [page].
  Future<Uint8List> readPages(int page) =>
      tag.send([0x30, page], label: 'READ ${hexByte(page)}');

  /// Escribe una página de 4 bytes y devuelve el ACK de la etiqueta.
  Future<Uint8List> writePage(int page, List<int> data) =>
      tag.send([0xA2, page, ...data], label: 'WRITE ${hexByte(page)}');

  /// Autentica con una contraseña de 4 bytes y devuelve el PACK.
  ///
  /// Lanza si la contraseña es incorrecta: la etiqueta responde con NAK.
  Future<Uint8List> sendPassword(List<int> password) =>
      tag.send([0x1B, ...password], label: 'PWD_AUTH');

  /// Pide los 8 bytes de identificación del producto.
  Future<Uint8List> getVersion() => tag.send([0x60], label: 'GET_VERSION');

  /// Pide la firma ECC de 32 bytes grabada en fábrica.
  Future<Uint8List> readSignature() =>
      tag.send([0x3C, 0x00], label: 'READ_SIG');
}
