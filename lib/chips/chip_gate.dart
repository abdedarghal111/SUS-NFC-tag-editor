// Único sitio donde se decide qué clase de chip atiende a cada etiqueta.

import '../nfc/tag_transceiver.dart';
import 'chip_identification.dart';
import 'chip_source.dart';
import 'errors/nfc_error.dart';
import 'nfc_chip.dart';
import 'type2/ntag210_chip.dart';
import 'type2/ntag212_chip.dart';
import 'type2/ntag213_chip.dart';
import 'type2/ntag215_chip.dart';
import 'type2/ntag216_chip.dart';
import 'type2/ultralight_ev1_11_chip.dart';
import 'type2/ultralight_ev1_21_chip.dart';

/// Constructor de un chip a partir del canal abierto con la etiqueta.
///
/// Con el canal a null construye solo la ficha del modelo, sin poder operar.
typedef ChipBuilder = NfcChip Function(TagTransceiver? tag);

/// Identifica la etiqueta y entrega el chip que la representa.
///
/// Es el único sitio donde se decide qué clase atiende a una etiqueta. Todo lo
/// demás trabaja ya con el chip, sin volver a preguntarse qué modelo es.
class ChipGate {
  const ChipGate._();

  /// Familia NTAG21x: byte de producto 0x04 en GET_VERSION.
  static const int _ntagProduct = 0x04;

  /// Familia Ultralight: byte de producto 0x03 en GET_VERSION.
  static const int _ultralightProduct = 0x03;

  /// Modelos reconocidos por su byte de tamaño dentro de cada familia.
  static const Map<int, Map<int, ChipBuilder>> _catalog = {
    _ntagProduct: {
      0x0B: Ntag210Chip.new,
      0x0E: Ntag212Chip.new,
      0x0F: Ntag213Chip.new,
      0x11: Ntag215Chip.new,
      0x13: Ntag216Chip.new,
    },
    _ultralightProduct: {
      0x0B: UltralightEv111Chip.new,
      0x0E: UltralightEv121Chip.new,
    },
  };

  /// Identifica la etiqueta y devuelve el chip, ya enganchado al canal.
  ///
  /// Entrada: el canal abierto. Salida: [ChipRecognized], o [ChipUnknown] si
  /// la etiqueta no contesta a GET_VERSION o declara un modelo que no está en
  /// el catálogo. Nunca supone un modelo. Lanza si se pierde la conexión.
  static Future<ChipIdentification> identify(TagTransceiver tag) async {
    final version = await _readVersion(tag);
    if (version == null || version.length < 7) {
      return ChipUnknown(version: version);
    }

    final builder = _catalog[version[2]]?[version[6]];
    if (builder == null) {
      return ChipUnknown(version: version);
    }
    return ChipRecognized(builder(tag)..source = ChipSource.declared);
  }

  /// Construye a mano el chip que se le indique, sobre el canal abierto.
  ///
  /// Para cuando el usuario elige el modelo por su cuenta.
  static NfcChip force(ChipBuilder builder, TagTransceiver tag) =>
      builder(tag)..source = ChipSource.chosen;

  /// Pide la versión sin dejar que un rechazo tumbe la identificación.
  ///
  /// Primero se lee la página 0: hay etiquetas que rechazan GET_VERSION si es
  /// el primer comando que reciben nada más engancharse.
  ///
  /// Salida: los bytes de la versión, o null si la etiqueta no contesta.
  static Future<List<int>?> _readVersion(TagTransceiver tag) async {
    try {
      await tag.send([0x30, 0x00], label: 'READ 0x00');
    } catch (error) {
      if (NfcError.isConnectionLost(error)) rethrow;
      tag.note('la etiqueta no contesta ni a la primera lectura', error);
      return null;
    }
    try {
      return await tag.send([0x60], label: 'GET_VERSION');
    } catch (error) {
      if (NfcError.isConnectionLost(error)) rethrow;
      tag.note('la etiqueta no admite GET_VERSION', error);
      return null;
    }
  }
}
