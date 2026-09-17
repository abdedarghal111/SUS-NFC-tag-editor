// Número de teléfono al que llamar.

import '../ndef_record_kind.dart';
import '../uri_payload.dart';

/// Teléfono que el móvil marca al leer la etiqueta.
class PhonePayload extends UriPayload {
  const PhonePayload(super.value);

  @override
  NdefRecordKind get kind => NdefRecordKind.phone;

  @override
  String get scheme => 'tel:';
}
