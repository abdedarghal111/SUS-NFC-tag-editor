// Capacidad de grabar contenido nuevo en la etiqueta.

import '../ndef/ndef_payload.dart';
import '../results/write_report.dart';

/// Graba un mensaje NDEF en la etiqueta.
abstract interface class Writable {
  /// Graba los registros como un único mensaje NDEF.
  ///
  /// Lanza [CapacityExceededError] si el contenido no cabe.
  Future<WriteReport> writeContent(
    List<NdefPayload> payloads, {
    List<int> password,
  });
}
