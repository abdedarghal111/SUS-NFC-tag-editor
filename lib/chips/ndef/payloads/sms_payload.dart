// Número al que enviar un SMS.

import '../ndef_record_kind.dart';
import '../uri_payload.dart';

/// Teléfono al que el móvil abre un SMS nuevo.
class SmsPayload extends UriPayload {
  const SmsPayload(super.value);

  @override
  NdefRecordKind get kind => NdefRecordKind.sms;

  @override
  String get scheme => 'sms:';
}
