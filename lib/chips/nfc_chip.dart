// Base común de todos los chips NFC que la app reconoce.

import 'dart:typed_data';

import '../nfc/tag_transceiver.dart';
import '../utils/hex.dart';
import 'chip_source.dart';
import 'errors/chip_busy_error.dart';
import 'errors/chip_mismatch_error.dart';

/// Situación del chip frente a la etiqueta que tiene delante.
enum ChipState {
  /// Enganchado y libre para atender una operación.
  ready,

  /// Operación en curso; no admite otra hasta terminar.
  working,

  /// La etiqueta se ha ido; hace falta volver a engancharlo.
  gone,
}

/// Chip NFC identificado, sea cual sea su familia.
///
/// Un chip es la sesión de trabajo con una etiqueta concreta: nace cuando se
/// identifica, atiende las operaciones que pida la app y se puede reutilizar
/// entre pasadas con [rebind] mientras sea la misma etiqueta.
abstract class NfcChip {
  NfcChip(this._tag) : uid = _tag.uid;

  TagTransceiver _tag;

  /// UID de la etiqueta con la que se creó el chip.
  ///
  /// Es la referencia contra la que se comprueba que no haya cambiado la
  /// etiqueta entre una operación y la siguiente.
  final Uint8List uid;

  ChipState _state = ChipState.ready;

  /// Cómo se ha averiguado que la etiqueta es de este modelo.
  ///
  /// Lo fija [ChipGate] al identificar. Vale [ChipSource.assumed] mientras
  /// nadie lo haya comprobado, que es lo que pasa al crear el chip a mano.
  ChipSource source = ChipSource.assumed;

  /// Nombre comercial del modelo.
  String get name;

  /// Indica si el modelo se ha probado contra una etiqueta real.
  ///
  /// Falso significa que el soporte está escrito según el datasheet pero nadie
  /// lo ha verificado con hardware en la mano.
  bool get devTested;

  /// Canal abierto con la etiqueta.
  TagTransceiver get tag => _tag;

  /// Situación actual del chip.
  ChipState get state => _state;

  /// Indica si hay una operación en curso.
  bool get isBusy => _state == ChipState.working;

  /// Reengancha el chip a una sesión nueva sobre la misma etiqueta.
  ///
  /// Lanza [ChipMismatchError] si el UID no coincide: el objeto guarda estado
  /// de una etiqueta concreta y aplicarlo a otra corrompería lo que se lea.
  void rebind(TagTransceiver tag) {
    if (!_sameUid(tag.uid)) {
      throw ChipMismatchError(
        expectedUid: hexBytes(uid),
        foundUid: hexBytes(tag.uid),
      );
    }
    _tag = tag;
    _state = ChipState.ready;
  }

  /// Comprueba que sigue siendo la etiqueta esperada antes de tocarla.
  ///
  /// Se ejecuta al principio de cada operación. Compara el UID, que no cuesta
  /// ningún comando porque ya viene de la selección.
  void verifyExpectedTag() {
    if (!_sameUid(_tag.uid)) {
      throw ChipMismatchError(
        expectedUid: hexBytes(uid),
        foundUid: hexBytes(_tag.uid),
      );
    }
  }

  /// Ejecuta una operación llevando el estado y la comprobación previa.
  ///
  /// Lanza [ChipMismatchError] si la etiqueta no es la misma, y [ChipBusyError]
  /// si ya hay otra operación en marcha.
  Future<T> run<T>(Future<T> Function() operation) async {
    if (_state == ChipState.working) {
      throw ChipBusyError(name);
    }
    verifyExpectedTag();
    _state = ChipState.working;
    try {
      return await operation();
    } finally {
      _state = await _tag.isPresent() ? ChipState.ready : ChipState.gone;
    }
  }

  bool _sameUid(Uint8List other) {
    if (other.length != uid.length) return false;
    for (var i = 0; i < uid.length; i++) {
      if (other[i] != uid[i]) return false;
    }
    return true;
  }
}
