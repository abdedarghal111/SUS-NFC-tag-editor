// Montaje y desmontaje del mensaje NDEF que viaja a la etiqueta.

import 'dart:convert';

import 'ndef_payload.dart';
import 'payloads/android_app_payload.dart';
import 'payloads/email_payload.dart';
import 'payloads/link_payload.dart';
import 'payloads/location_payload.dart';
import 'payloads/phone_payload.dart';
import 'payloads/sms_payload.dart';
import 'payloads/text_payload.dart';
import 'payloads/unknown_payload.dart';
import 'uri_prefixes.dart';

/// Posición y tamaño del mensaje NDEF dentro de la memoria de la etiqueta.
class NdefLocation {
  const NdefLocation(this.start, this.length);

  /// Desplazamiento del primer byte del mensaje desde la página 4.
  final int start;

  /// Longitud del mensaje en bytes.
  final int length;

  /// Último byte del mensaje, sin incluir.
  int get end => start + length;
}

/// Traductor entre la lista de contenidos de la app y los bytes que viajan a
/// la etiqueta.
///
/// Se monta el mensaje a mano en vez de usar la API NDEF de Android porque así
/// se graba con comandos WRITE normales, y eso permite autenticar antes en la
/// misma sesión.
class NdefMessageCodec {
  const NdefMessageCodec._();

  /// Marca de bloque NDEF dentro del área TLV.
  static const int _ndefTag = 0x03;

  /// Marca de fin de datos.
  static const int _terminatorTag = 0xFE;

  /// Monta el bloque completo que se graba desde la página 4.
  static List<int> encode(List<NdefPayload> payloads) {
    final message = <int>[];
    for (var i = 0; i < payloads.length; i++) {
      message.addAll(
        _encodeRecord(
          payloads[i],
          isFirst: i == 0,
          isLast: i == payloads.length - 1,
        ),
      );
    }

    final block = <int>[_ndefTag];
    if (message.length < 0xFF) {
      block.add(message.length);
    } else {
      block.addAll([0xFF, message.length >> 8, message.length & 0xFF]);
    }
    block
      ..addAll(message)
      ..add(_terminatorTag);

    while (block.length % 4 != 0) {
      block.add(0x00);
    }
    return block;
  }

  /// Bloque que deja la etiqueta vacía pero con formato NDEF válido.
  static List<int> emptyBlock() => [_ndefTag, 0x00, _terminatorTag, 0x00];

  /// Busca el bloque NDEF dentro de los bytes leídos.
  static NdefLocation? locate(List<int> bytes) {
    var index = 0;
    while (index < bytes.length) {
      final tag = bytes[index];
      if (tag == _terminatorTag) return null;
      if (tag == 0x00) {
        index++;
        continue;
      }
      if (index + 1 >= bytes.length) return null;

      int length;
      var valueStart = index + 2;
      if (bytes[index + 1] == 0xFF) {
        if (index + 3 >= bytes.length) return null;
        length = (bytes[index + 2] << 8) | bytes[index + 3];
        valueStart = index + 4;
      } else {
        length = bytes[index + 1];
      }

      if (tag == _ndefTag) return NdefLocation(valueStart, length);
      index = valueStart + length;
    }
    return null;
  }

  /// Desmonta el mensaje en contenidos legibles.
  static List<NdefPayload> decode(List<int> message) {
    final payloads = <NdefPayload>[];
    var index = 0;

    while (index < message.length) {
      final header = message[index];
      final tnf = header & 0x07;
      final isShort = header & 0x10 != 0;
      final hasId = header & 0x08 != 0;
      index++;
      if (index >= message.length) break;

      final typeLength = message[index];
      index++;

      int payloadLength;
      if (isShort) {
        if (index >= message.length) break;
        payloadLength = message[index];
        index += 1;
      } else {
        if (index + 3 >= message.length) break;
        payloadLength =
            (message[index] << 24) |
            (message[index + 1] << 16) |
            (message[index + 2] << 8) |
            message[index + 3];
        index += 4;
      }

      var idLength = 0;
      if (hasId) {
        if (index >= message.length) break;
        idLength = message[index];
        index++;
      }

      if (index + typeLength + idLength + payloadLength > message.length) break;
      final type = utf8.decode(
        message.sublist(index, index + typeLength),
        allowMalformed: true,
      );
      index += typeLength + idLength;
      final payload = message.sublist(index, index + payloadLength);
      index += payloadLength;

      payloads.add(_decodeRecord(tnf, type, payload));

      // El bit ME marca el último registro del mensaje.
      if (header & 0x40 != 0) break;
    }
    return payloads;
  }

  /// Serializa un registro con su cabecera de banderas y longitudes.
  static List<int> _encodeRecord(
    NdefPayload payload, {
    required bool isFirst,
    required bool isLast,
  }) {
    final record = payload.encode();
    final isShort = record.payload.length < 256;

    var header = record.tnf;
    if (isFirst) header |= 0x80;
    if (isLast) header |= 0x40;
    if (isShort) header |= 0x10;

    return [
      header,
      record.type.length,
      if (isShort)
        record.payload.length
      else ...[
        record.payload.length >> 24 & 0xFF,
        record.payload.length >> 16 & 0xFF,
        record.payload.length >> 8 & 0xFF,
        record.payload.length & 0xFF,
      ],
      ...record.type,
      ...record.payload,
    ];
  }

  /// Reconstruye el contenido de un registro según su TNF y su tipo.
  static NdefPayload _decodeRecord(int tnf, String type, List<int> payload) {
    if (tnf == 0x01 && type == 'T' && payload.isNotEmpty) {
      final languageLength = payload[0] & 0x3F;
      return TextPayload(
        utf8.decode(payload.sublist(1 + languageLength), allowMalformed: true),
      );
    }
    if (tnf == 0x01 && type == 'U' && payload.isNotEmpty) {
      return _payloadForUri(UriPrefix.expand(payload));
    }
    if (tnf == 0x04 && type == 'android.com:pkg') {
      return AndroidAppPayload(utf8.decode(payload, allowMalformed: true));
    }
    return UnknownPayload(
      '[$type] ${utf8.decode(payload, allowMalformed: true)}',
    );
  }

  /// Elige la clase de contenido que corresponde al esquema del URI.
  static NdefPayload _payloadForUri(String uri) {
    if (uri.startsWith('tel:')) return PhonePayload(uri);
    if (uri.startsWith('mailto:')) return EmailPayload(uri);
    if (uri.startsWith('sms:')) return SmsPayload(uri);
    if (uri.startsWith('geo:')) return LocationPayload(uri);
    return LinkPayload(uri);
  }
}
