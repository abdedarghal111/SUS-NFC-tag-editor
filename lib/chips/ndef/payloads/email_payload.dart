// Dirección de correo.

import '../ndef_record_kind.dart';
import '../uri_payload.dart';

/// Correo al que el móvil abre un mensaje nuevo.
class EmailPayload extends UriPayload {
  const EmailPayload(super.value);

  @override
  NdefRecordKind get kind => NdefRecordKind.email;

  @override
  String get scheme => 'mailto:';
}
