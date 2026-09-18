// Puente con los ajustes de NFC del sistema, que la app no puede tocar.

import 'package:flutter/services.dart';

/// Lleva al usuario a los ajustes de NFC para que lo active él mismo.
///
/// Ninguna app puede encender el NFC por su cuenta.
class NfcSettings {
  const NfcSettings._();

  static const MethodChannel _channel = MethodChannel(
    'es.abderra.sus_nfc_tag_editor/nfc_settings',
  );

  /// Abre los ajustes de NFC. Salida: false si el sistema no los ofrece.
  static Future<bool> open() async {
    try {
      return await _channel.invokeMethod<bool>('openNfcSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
