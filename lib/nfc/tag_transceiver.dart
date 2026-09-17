// Canal de bajo nivel con la etiqueta: envía bytes y deja traza.

import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import '../utils/hex.dart';

/// Canal de bajo nivel con una etiqueta ya enganchada.
///
/// Solo sabe de radio: manda bytes, recoge la respuesta y anota el intercambio.
/// Qué bytes hay que mandar lo decide el chip, que es quien conoce su modelo.
class TagTransceiver {
  TagTransceiver(this._nfcA, this.trace);

  final NfcAAndroid _nfcA;

  /// Líneas de traza de la operación en curso, en orden de envío.
  final List<String> trace;

  Uint8List get uid => _nfcA.tag.id;

  Uint8List get atqa => _nfcA.atqa;

  int get sak => _nfcA.sak;

  List<String> get techList => _nfcA.tag.techList;

  /// Amplía el margen por respuesta: los clones tardan más que un NXP y con el
  /// valor por defecto la conexión se da por perdida.
  Future<void> applyTimeout(int milliseconds) async {
    try {
      await _nfcA.setTimeout(milliseconds);
    } catch (_) {
      trace.add('Esta etiqueta no admite cambiar el tiempo de espera.');
    }
  }

  /// Envía bytes en crudo, deja traza del intercambio y devuelve la respuesta.
  Future<Uint8List> send(List<int> command, {String? label}) async {
    trace.add('> ${label == null ? '' : '$label: '}${hexBytes(command)}');
    final response = await _nfcA.transceive(Uint8List.fromList(command));
    trace.add('< ${response.isEmpty ? '(vacío)' : hexBytes(response)}');
    return response;
  }

  /// Comprueba si la etiqueta sigue en el campo, sin ensuciar la traza.
  Future<bool> isPresent() async {
    try {
      await _nfcA.transceive(Uint8List.fromList([0x30, 0x00]));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Construye el canal, o null si la etiqueta no habla NfcA.
  static TagTransceiver? from(NfcTag tag, List<String> trace) {
    final nfcA = NfcAAndroid.from(tag);
    return nfcA == null ? null : TagTransceiver(nfcA, trace);
  }
}
